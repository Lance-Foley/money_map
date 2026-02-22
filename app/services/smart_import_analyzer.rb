# frozen_string_literal: true

class SmartImportAnalyzer
  CATEGORY_MAPPING = {
    "Shopping" => "Lifestyle",
    "Food & Dining" => "Food",
    "Auto & Transport" => "Transportation",
    "Bills & Utilities" => "Utilities",
    "Home" => "Housing",
    "Housing" => "Housing",
    "Credit Card Payment" => "Debt",
    "Internal Transfer" => "Savings",
    "External Deposit" => nil,
    "External Withdrawal" => "Personal",
    "Financial" => "Insurance",
    "Health & Fitness" => "Health",
    "Check Withdrawal" => "Personal",
    "Travel" => "Lifestyle"
  }.freeze

  DATE_PATTERNS = /\b(date|settled|posted|trans(action)?)\b/i
  AMOUNT_PATTERNS = /\b(amount|total|sum|value|debit|credit)\b/i
  DESCRIPTION_PATTERNS = /\b(description|desc|memo|payee|merchant|name|details?)\b/i
  CATEGORY_PATTERNS = /\b(category|type|class|group|tag)\b/i

  # Minimum occurrences to consider something recurring
  MIN_RECURRING_COUNT = 3

  # Tolerance in days for frequency detection
  FREQUENCY_TOLERANCES = {
    weekly: { target: 7, tolerance: 2 },
    biweekly: { target: 14, tolerance: 3 },
    monthly: { target: 30, tolerance: 5 }
  }.freeze

  def initialize(csv_content, account_name: nil, institution_name: nil)
    @csv_content = csv_content
    @account_name = account_name
    @institution_name = institution_name
  end

  def analyze
    rows = parse_csv
    return { error: "No data found in CSV" } if rows.empty?

    columns = detect_columns(rows.first.headers)
    transactions = parse_transactions(rows, columns)
    return { error: "No valid transactions found" } if transactions.empty?

    {
      detected_columns: columns,
      account: detect_primary_account(transactions),
      recurring_income: detect_recurring_income(transactions),
      recurring_bills: detect_recurring_bills(transactions),
      recurring_transfers: detect_recurring_transfers(transactions),
      detected_accounts: detect_accounts(transactions),
      category_mapping: build_category_mapping(transactions),
      budget_suggestions: build_budget_suggestions(transactions),
      transactions: transactions,
      summary: build_summary(transactions)
    }
  end

  private

  def parse_csv
    require "csv"
    table = CSV.parse(@csv_content, headers: true)
    table.select { |row| row.to_h.values.any?(&:present?) }
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "Invalid CSV format: #{e.message}"
  end

  def detect_columns(headers)
    {
      date: headers.find { |h| h.match?(DATE_PATTERNS) } || headers.first,
      amount: headers.find { |h| h.match?(AMOUNT_PATTERNS) } || headers[1],
      description: headers.find { |h| h.match?(DESCRIPTION_PATTERNS) } || headers[2],
      category: headers.find { |h| h.match?(CATEGORY_PATTERNS) }
    }.compact
  end

  def parse_transactions(rows, columns)
    rows.filter_map do |row|
      date_str = row[columns[:date]]
      amount_str = row[columns[:amount]]
      description = row[columns[:description]]
      category = columns[:category] ? row[columns[:category]] : nil

      next unless date_str.present? && amount_str.present?

      date = begin
        Date.parse(date_str)
      rescue Date::Error
        nil
      end
      next unless date

      raw_amount = amount_str.to_s.gsub(/[^0-9.\-]/, "").to_f

      {
        date: date,
        amount: raw_amount,
        abs_amount: raw_amount.abs,
        description: description&.strip,
        csv_category: category&.strip,
        transaction_type: determine_transaction_type(raw_amount, category),
        mapped_category: map_category(category)
      }
    end.sort_by { |t| t[:date] }
  end

  def determine_transaction_type(amount, category)
    return :income if amount > 0
    return :transfer if category&.match?(/internal transfer/i)
    :expense
  end

  def detect_primary_account(transactions)
    {
      name: @account_name.presence || "Primary Checking",
      type: :checking,
      institution: @institution_name.presence
    }
  end

  def detect_recurring_income(transactions)
    income_txns = transactions.select { |t| t[:transaction_type] == :income }
    detect_recurring_pattern(income_txns).map do |pattern|
      {
        source_name: pattern[:description],
        frequency: pattern[:frequency],
        amount: pattern[:avg_amount],
        start_date: pattern[:first_date],
        category: "Income"
      }
    end
  end

  def detect_recurring_bills(transactions)
    expense_txns = transactions.select { |t| t[:transaction_type] == :expense }
    detect_recurring_pattern(expense_txns).map do |pattern|
      {
        name: clean_bill_name(pattern[:description]),
        frequency: pattern[:frequency],
        amount: pattern[:avg_amount],
        due_day: pattern[:common_day],
        category: pattern[:mapped_category] || "Personal",
        csv_category: pattern[:csv_category]
      }
    end
  end

  def detect_recurring_transfers(transactions)
    transfer_txns = transactions.select { |t| t[:transaction_type] == :transfer }
    detect_recurring_pattern(transfer_txns).map do |pattern|
      to_account = extract_transfer_target(pattern[:description])
      {
        name: pattern[:description],
        frequency: pattern[:frequency],
        amount: pattern[:avg_amount],
        to_account: to_account
      }
    end
  end

  def detect_accounts(transactions)
    accounts = []

    # Detect from Internal Transfer descriptions
    transfer_txns = transactions.select { |t| t[:csv_category]&.match?(/internal transfer/i) }
    transfer_txns.each do |t|
      target = extract_transfer_target(t[:description])
      next unless target

      accounts << {
        name: target,
        type: guess_account_type(target),
        source: "Internal Transfer descriptions"
      }
    end

    # Detect from Credit Card Payment descriptions
    cc_txns = transactions.select { |t| t[:csv_category]&.match?(/credit card payment/i) }
    cc_txns.each do |t|
      name = extract_credit_card_name(t[:description])
      next unless name

      accounts << {
        name: name,
        type: :credit_card,
        source: "Credit Card Payment descriptions"
      }
    end

    # Deduplicate by name
    accounts.uniq { |a| a[:name] }
  end

  def build_category_mapping(transactions)
    csv_categories = transactions.map { |t| t[:csv_category] }.compact.uniq
    csv_categories.each_with_object({}) do |cat, mapping|
      mapping[cat] = map_category(cat)
    end
  end

  def build_budget_suggestions(transactions)
    # Group expenses by mapped category, compute monthly averages
    expense_txns = transactions.select { |t| t[:transaction_type] == :expense }
    return [] if expense_txns.empty?

    date_range_months = calculate_months_span(transactions)
    return [] if date_range_months.zero?

    by_category = expense_txns.group_by { |t| t[:mapped_category] || "Personal" }

    by_category.filter_map do |category, txns|
      total = txns.sum { |t| t[:abs_amount] }
      monthly_avg = (total / date_range_months).round(2)

      # Group into budget items by description pattern
      items = txns.group_by { |t| clean_bill_name(t[:description]) }
        .map do |name, item_txns|
          item_total = item_txns.sum { |t| t[:abs_amount] }
          item_avg = (item_total / date_range_months).round(2)
          { name: name, amount: item_avg }
        end
        .sort_by { |i| -i[:amount] }
        .first(10) # Limit to top 10 items per category

      {
        category: category,
        monthly_total: monthly_avg,
        items: items
      }
    end.sort_by { |s| -s[:monthly_total] }
  end

  def build_summary(transactions)
    income_txns = transactions.select { |t| t[:transaction_type] == :income }
    expense_txns = transactions.select { |t| t[:transaction_type] == :expense }
    transfer_txns = transactions.select { |t| t[:transaction_type] == :transfer }
    months = calculate_months_span(transactions)

    {
      total_transactions: transactions.size,
      date_range: {
        start: transactions.first[:date],
        end: transactions.last[:date]
      },
      months_covered: months,
      total_income: income_txns.sum { |t| t[:abs_amount] }.round(2),
      total_expenses: expense_txns.sum { |t| t[:abs_amount] }.round(2),
      total_transfers: transfer_txns.sum { |t| t[:abs_amount] }.round(2),
      monthly_income_avg: months > 0 ? (income_txns.sum { |t| t[:abs_amount] } / months).round(2) : 0,
      monthly_expense_avg: months > 0 ? (expense_txns.sum { |t| t[:abs_amount] } / months).round(2) : 0,
      categories_found: transactions.map { |t| t[:csv_category] }.compact.uniq.size
    }
  end

  # --- Pattern Detection ---

  def detect_recurring_pattern(transactions)
    # Group by normalized description
    grouped = transactions.group_by { |t| normalize_description(t[:description]) }

    grouped.filter_map do |desc, txns|
      next if txns.size < MIN_RECURRING_COUNT

      amounts = txns.map { |t| t[:abs_amount] }
      avg_amount = (amounts.sum / amounts.size).round(2)

      # Check amount consistency (within 20% of average, or exact match)
      amount_consistent = amounts.all? { |a| (a - avg_amount).abs <= avg_amount * 0.2 }
      next unless amount_consistent

      frequency = detect_frequency(txns.map { |t| t[:date] }.sort)
      next unless frequency

      days = txns.map { |t| t[:date].day }
      common_day = days.tally.max_by { |_, count| count }&.first

      {
        description: txns.first[:description],
        frequency: frequency,
        avg_amount: avg_amount,
        occurrences: txns.size,
        first_date: txns.map { |t| t[:date] }.min,
        last_date: txns.map { |t| t[:date] }.max,
        common_day: common_day,
        mapped_category: txns.first[:mapped_category],
        csv_category: txns.first[:csv_category]
      }
    end
  end

  def detect_frequency(dates)
    return nil if dates.size < 2

    gaps = dates.each_cons(2).map { |a, b| (b - a).to_i }
    avg_gap = gaps.sum.to_f / gaps.size

    FREQUENCY_TOLERANCES.each do |freq, config|
      if (avg_gap - config[:target]).abs <= config[:tolerance]
        return freq
      end
    end

    nil
  end

  def normalize_description(desc)
    return "" unless desc
    # Remove trailing numbers, dates, reference codes
    desc.strip
      .gsub(/\s*#\d+\s*$/, "")
      .gsub(/\s*\d{4,}$/, "")
      .gsub(/\s+/, " ")
      .downcase
  end

  def clean_bill_name(description)
    return "Unknown" unless description
    # Remove common suffixes like "Payment", reference numbers
    description.strip
      .gsub(/\s*#\d+.*$/, "")
      .gsub(/\s*Payment$/i, "")
      .gsub(/\s+$/, "")
  end

  def extract_transfer_target(description)
    return nil unless description
    match = description.match(/transfer to (.+)/i)
    match ? match[1].strip : nil
  end

  def extract_credit_card_name(description)
    return nil unless description
    # "Apple Credit Card Payment" -> "Apple Credit Card"
    # "Chase Credit Card Payment" -> "Chase Credit Card"
    cleaned = description.gsub(/\s*Payment$/i, "").strip
    cleaned.present? ? cleaned : nil
  end

  def guess_account_type(name)
    return :credit_card if name.match?(/credit card/i)
    return :savings if name.match?(/saving|emergency|fund/i)
    return :checking if name.match?(/checking/i)
    :savings # Default for transfer targets
  end

  def map_category(csv_category)
    return nil unless csv_category
    CATEGORY_MAPPING[csv_category]
  end

  def calculate_months_span(transactions)
    return 0 if transactions.empty?
    first_date = transactions.map { |t| t[:date] }.min
    last_date = transactions.map { |t| t[:date] }.max
    months = ((last_date.year * 12 + last_date.month) - (first_date.year * 12 + first_date.month)) + 1
    [months, 1].max
  end
end
