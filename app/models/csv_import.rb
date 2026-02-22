class CsvImport < ApplicationRecord
  belongs_to :account, optional: true
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3, analyzed: 4 }

  def analyze!
    content = file.download
    analyzer = SmartImportAnalyzer.new(
      content,
      account_name: nil,
      institution_name: nil
    )
    results = analyzer.analyze

    if results[:error]
      update!(status: :failed, error_log: results[:error])
    else
      update!(
        status: :analyzed,
        analysis_results: serialize_analysis(results),
        column_mapping: results[:detected_columns].transform_keys(&:to_s)
      )
    end

    results
  end

  def process!
    update!(status: :processing)
    imported = 0
    skipped = 0
    errors = []

    require "csv"
    content = file.download
    CSV.parse(content, headers: true) do |row|
      begin
        date_col = column_mapping&.dig("date") || "Date"
        amount_col = column_mapping&.dig("amount") || "Amount"
        desc_col = column_mapping&.dig("description") || "Description"

        raw_amount = row[amount_col].to_s.gsub(/[^0-9.\-]/, "").to_f

        account.transactions.create!(
          date: Date.parse(row[date_col]),
          amount: raw_amount.abs,
          description: row[desc_col],
          transaction_type: raw_amount >= 0 ? :income : :expense,
          imported: true
        )
        imported += 1
      rescue => e
        skipped += 1
        errors << "Row #{imported + skipped}: #{e.message}"
      end
    end

    update!(
      status: :completed,
      records_imported: imported,
      records_skipped: skipped,
      error_log: errors.any? ? errors.join("\n") : nil
    )
  rescue => e
    update!(status: :failed, error_log: e.message)
  end

  def parsed_analysis
    return nil unless analysis_results
    case analysis_results
    when String then JSON.parse(analysis_results, symbolize_names: true)
    when Hash then analysis_results.deep_symbolize_keys
    else nil
    end
  end

  private

  def serialize_analysis(results)
    # Convert Date objects to strings for JSON storage
    serializable = results.deep_dup
    serializable[:transactions] = results[:transactions]&.map do |t|
      t.merge(date: t[:date].to_s)
    end
    if serializable.dig(:summary, :date_range)
      serializable[:summary][:date_range][:start] = serializable[:summary][:date_range][:start].to_s
      serializable[:summary][:date_range][:end] = serializable[:summary][:date_range][:end].to_s
    end
    serializable[:recurring_income]&.each { |r| r[:start_date] = r[:start_date].to_s if r[:start_date] }
    serializable
  end
end
