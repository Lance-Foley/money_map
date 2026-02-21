class CsvImport < ApplicationRecord
  belongs_to :account
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :account, presence: true

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
end
