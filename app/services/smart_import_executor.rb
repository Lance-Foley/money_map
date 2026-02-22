# frozen_string_literal: true

class SmartImportExecutor
  def initialize(csv_import, analysis, selections)
    @csv_import = csv_import
    @analysis = analysis
    @selections = selections.to_h.deep_symbolize_keys
  end

  def execute!
    ActiveRecord::Base.transaction do
      @csv_import.update!(status: :processing)

      account = create_primary_account
      created_accounts = create_detected_accounts
      created_income = create_recurring_income
      created_bills = create_recurring_bills
      created_budget_items = create_budget_items
      imported_count, skipped_count = import_transactions(account)

      # Run ActionPlanGenerator to populate future months
      ActionPlanGenerator.new(months_ahead: 3).generate!

      @csv_import.update!(
        status: :completed,
        account: account,
        records_imported: imported_count,
        records_skipped: skipped_count
      )

      {
        success: true,
        message: build_success_message(
          account: account,
          accounts: created_accounts,
          income: created_income,
          bills: created_bills,
          budget_items: created_budget_items,
          imported: imported_count,
          skipped: skipped_count
        )
      }
    end
  rescue => e
    @csv_import.update(status: :failed, error_log: e.message)
    { success: false, message: "Import failed: #{e.message}" }
  end

  private

  def create_primary_account
    # Use existing account if linked, otherwise create one
    if @csv_import.account_id.present?
      return @csv_import.account
    end

    account_data = @analysis[:account] || {}
    name = account_data[:name].presence || "Imported Account"
    account_type = account_data[:type]&.to_sym || :checking

    Account.find_or_create_by!(name: name) do |a|
      a.account_type = account_type
      a.institution_name = account_data[:institution]
      a.balance = 0
    end
  end

  def create_detected_accounts
    accounts_data = @analysis[:detected_accounts] || []
    selected = selected_items(:accounts, accounts_data)

    selected.filter_map do |acct_data|
      name = acct_data[:name]
      next if name.blank?
      next if Account.exists?(name: name)

      Account.create!(
        name: name,
        account_type: acct_data[:type]&.to_sym || :savings,
        balance: 0,
        active: true
      )
    end
  end

  def create_recurring_income
    income_data = @analysis[:recurring_income] || []
    selected = selected_items(:income, income_data)
    return [] if selected.empty?

    selected.filter_map do |inc_data|
      source_name = inc_data[:source_name]
      next if source_name.blank?
      next if RecurringTransaction.exists?(name: source_name, direction: :income)

      freq = map_frequency(inc_data[:frequency])
      start_date = parse_date(inc_data[:start_date]) || Date.current.beginning_of_month
      due_day = start_date.day.clamp(1, 31)

      RecurringTransaction.create!(
        name: source_name,
        amount: inc_data[:amount] || 0,
        frequency: freq,
        due_day: due_day,
        start_date: start_date,
        direction: :income,
        active: true
      )
    end
  end

  def create_recurring_bills
    bills_data = @analysis[:recurring_bills] || []
    selected = selected_items(:bills, bills_data)

    selected.filter_map do |bill_data|
      name = bill_data[:name]
      next if name.blank?
      next if RecurringTransaction.exists?(name: name, direction: :expense)

      category = find_or_create_category(bill_data[:category])
      freq = map_frequency(bill_data[:frequency])
      due_day = (bill_data[:due_day] || 1).to_i.clamp(1, 31)

      RecurringTransaction.create!(
        name: name,
        amount: bill_data[:amount] || 0,
        frequency: freq,
        due_day: due_day,
        start_date: Date.new(Date.current.year, Date.current.month, [due_day, Date.current.end_of_month.day].min),
        budget_category: category,
        direction: :expense,
        active: true
      )
    end
  end

  def create_budget_items
    suggestions = @analysis[:budget_suggestions] || []
    return [] if suggestions.empty?

    period = current_budget_period
    items = []

    suggestions.each do |suggestion|
      category = find_or_create_category(suggestion[:category])
      next unless category

      # Create one budget item per category with the monthly total
      next if period.budget_items.exists?(budget_category: category, name: suggestion[:category])

      items << period.budget_items.create!(
        budget_category: category,
        name: suggestion[:category],
        planned_amount: suggestion[:monthly_total] || 0
      )
    end

    period.recalculate_totals!
    items
  end

  def import_transactions(account)
    return [0, 0] unless @selections[:import_transactions].to_s == "1"

    transactions = @analysis[:transactions] || []
    imported = 0
    skipped = 0

    transactions.each do |txn|
      begin
        date = parse_date(txn[:date])
        next unless date

        amount = txn[:abs_amount] || txn[:amount].to_f.abs
        txn_type = case txn[:transaction_type]&.to_sym
                   when :income then :income
                   when :transfer then :transfer
                   else :expense
                   end

        account.transactions.create!(
          date: date,
          amount: amount,
          description: txn[:description],
          transaction_type: txn_type,
          imported: true
        )
        imported += 1
      rescue => e
        skipped += 1
      end
    end

    [imported, skipped]
  end

  # --- Helpers ---

  def selected_items(key, data)
    selection = @selections.dig(key)
    return data if selection.nil? # Default: all selected

    data.each_with_index.filter_map do |item, i|
      item if selection[i.to_s.to_sym].to_s == "1" || selection[i.to_s].to_s == "1"
    end
  end

  def current_budget_period
    today = Date.current
    BudgetPeriod.find_or_create_by!(year: today.year, month: today.month)
  end

  def find_or_create_category(name)
    return nil if name.blank?
    BudgetCategory.find_by(name: name) || BudgetCategory.create!(
      name: name,
      position: (BudgetCategory.maximum(:position) || 0) + 1
    )
  end

  def map_frequency(freq)
    case freq&.to_sym
    when :weekly then :weekly
    when :biweekly then :biweekly
    when :monthly then :monthly
    when :quarterly then :quarterly
    else :monthly
    end
  end

  def parse_date(date_val)
    case date_val
    when Date then date_val
    when String then Date.parse(date_val) rescue nil
    else nil
    end
  end

  def build_success_message(account:, accounts:, income:, bills:, budget_items:, imported:, skipped:)
    parts = []
    parts << "Imported #{imported} transactions into #{account.name}"
    parts << "#{skipped} skipped" if skipped > 0
    parts << "Created #{accounts.size} accounts" if accounts.any?
    parts << "#{income.size} recurring income" if income.any?
    parts << "#{bills.size} recurring expenses" if bills.any?
    parts << "#{budget_items.size} budget items" if budget_items.any?
    parts.join(". ") + "."
  end
end
