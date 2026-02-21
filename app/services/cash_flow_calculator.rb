class CashFlowCalculator
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def calculate
    starting_balance = compute_starting_balance
    events = collect_events
    timeline = build_timeline(events, starting_balance)
    negative_dates = timeline.select { |e| e[:running_balance] < 0 }.map { |e| e[:date] }.uniq
    monthly_summary = build_monthly_summary(timeline)
    chart_data = build_chart_data(timeline, starting_balance)

    {
      starting_balance: starting_balance,
      timeline: timeline,
      negative_dates: negative_dates,
      monthly_summary: monthly_summary,
      chart_data: chart_data
    }
  end

  private

  def compute_starting_balance
    Account.active.where(account_type: [:checking, :savings]).sum(:balance).to_f
  end

  def collect_events
    events = []

    collect_expense_events(events)
    collect_income_events(events)

    # Sort by date, then income before expense on same day
    events.sort_by { |e| [e[:date], e[:type] == :income ? 0 : 1] }
  end

  def collect_expense_events(events)
    BudgetItem.joins(:budget_period)
      .where(expected_date: @start_date..@end_date)
      .find_each do |item|
        events << {
          date: item.expected_date,
          name: item.name,
          amount: -(item.planned_amount || 0).to_f,
          type: :expense,
          source: item.from_recurring? ? :recurring : :manual,
          record_type: "BudgetItem",
          record_id: item.id
        }
      end
  end

  def collect_income_events(events)
    Income.joins(:budget_period)
      .where(pay_date: @start_date..@end_date)
      .find_each do |income|
        events << {
          date: income.pay_date,
          name: income.source_name,
          amount: (income.expected_amount || 0).to_f,
          type: :income,
          source: income.recurring? ? :recurring : :manual,
          record_type: "Income",
          record_id: income.id
        }
      end
  end

  def build_timeline(events, starting_balance)
    running = starting_balance
    events.map do |event|
      running += event[:amount]
      event.merge(running_balance: running.round(2))
    end
  end

  def build_monthly_summary(timeline)
    return [] if timeline.empty?

    timeline.group_by { |e| [e[:date].year, e[:date].month] }.map do |(year, month), events|
      total_income = events.select { |e| e[:type] == :income }.sum { |e| e[:amount] }
      total_expenses = events.select { |e| e[:type] == :expense }.sum { |e| e[:amount].abs }

      {
        year: year,
        month: month,
        display_name: Date.new(year, month, 1).strftime("%B %Y"),
        total_income: total_income.round(2),
        total_expenses: total_expenses.round(2),
        surplus: (total_income - total_expenses).round(2),
        ending_balance: events.last[:running_balance]
      }
    end
  end

  def build_chart_data(timeline, starting_balance)
    return { labels: [], data: [] } if timeline.empty?

    points = [{ label: @start_date.strftime("%b %d"), value: starting_balance }]
    timeline.each do |event|
      points << { label: event[:date].strftime("%b %d"), value: event[:running_balance] }
    end

    {
      labels: points.map { |p| p[:label] },
      data: points.map { |p| p[:value] }
    }
  end
end
