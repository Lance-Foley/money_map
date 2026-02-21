class ActionPlanGenerator
  def initialize(months_ahead: 3, from_date: Date.current)
    @months_ahead = months_ahead
    @from_date = from_date.beginning_of_month.next_month
  end

  def generate!
    periods = ensure_periods_exist
    generate_bill_items(periods)
    generate_income_entries(periods)
    recalculate_totals(periods)
  end

  private

  def ensure_periods_exist
    (0...@months_ahead).map do |offset|
      target = @from_date >> offset
      BudgetPeriod.find_or_create_by!(year: target.year, month: target.month)
    end
  end

  def generate_bill_items(periods)
    RecurringBill.active.includes(:budget_category).find_each do |bill|
      periods.each do |period|
        next if period.budget_items.exists?(recurring_bill: bill)

        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = bill.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          category = bill.budget_category || BudgetCategory.find_by(name: "Personal")
          period.budget_items.create!(
            name: bill.name,
            planned_amount: bill.amount,
            expected_date: occurrence_date,
            recurring_bill: bill,
            budget_category: category,
            auto_generated: true
          )
        end
      end
    end
  end

  def generate_income_entries(periods)
    Income.recurring_sources.find_each do |source|
      periods.each do |period|
        next if period.incomes.exists?(recurring_source_id: source.id)
        next unless source.start_date.present?

        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = source.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          period.incomes.create!(
            source_name: source.source_name,
            expected_amount: source.expected_amount,
            pay_date: occurrence_date,
            start_date: source.start_date,
            frequency: source.frequency,
            recurring: true,
            auto_generated: true,
            recurring_source_id: source.id
          )
        end
      end
    end
  end

  def recalculate_totals(periods)
    periods.each(&:recalculate_totals!)
  end
end
