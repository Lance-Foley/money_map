class ActionPlanGenerator
  def initialize(months_ahead: 3, from_date: Date.current)
    @months_ahead = months_ahead
    @from_date = from_date.beginning_of_month
  end

  def generate!
    periods = ensure_periods_exist
    clear_auto_generated(periods)
    generate_expense_items(periods)
    generate_income_entries(periods)
    recalculate_totals(periods)
  end

  private

  def clear_auto_generated(periods)
    periods.each do |period|
      period.budget_items.where(auto_generated: true).delete_all
      period.incomes.where(auto_generated: true).delete_all
    end
  end

  def ensure_periods_exist
    (0...@months_ahead).map do |offset|
      target = @from_date >> offset
      BudgetPeriod.find_or_create_by!(year: target.year, month: target.month)
    end
  end

  def generate_expense_items(periods)
    RecurringTransaction.active.expenses.includes(:budget_category).find_each do |txn|
      periods.each do |period|
        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = txn.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          category = txn.budget_category || BudgetCategory.find_by(name: "Personal")
          period.budget_items.create!(
            name: txn.name,
            planned_amount: txn.amount,
            expected_date: occurrence_date,
            recurring_transaction: txn,
            budget_category: category,
            auto_generated: true
          )
        end
      end
    end
  end

  def generate_income_entries(periods)
    RecurringTransaction.active.incomes_only.find_each do |txn|
      periods.each do |period|
        next unless txn.start_date.present?

        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = txn.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          period.incomes.create!(
            source_name: txn.name,
            expected_amount: txn.amount,
            pay_date: occurrence_date,
            recurring: true,
            auto_generated: true,
            recurring_transaction_id: txn.id
          )
        end
      end
    end
  end

  def recalculate_totals(periods)
    periods.each(&:recalculate_totals!)
  end
end
