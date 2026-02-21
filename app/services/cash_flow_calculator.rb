class CashFlowCalculator
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def calculate
    starting_balance = compute_starting_balance
    events = collect_events
    timeline = build_timeline(events, starting_balance)
    negative_dates = timeline.select { |e| e[:is_negative] }.map { |e| e[:date] }.uniq
    monthly_summary = build_monthly_summary(timeline)

    {
      starting_balance: starting_balance,
      timeline: timeline,
      negative_dates: negative_dates,
      monthly_summary: monthly_summary
    }
  end

  private

  def compute_starting_balance
    Account.active.where(account_type: :checking).sum(:balance).to_f
  end

  def primary_checking_name
    @primary_checking_name ||= Account.active.where(account_type: :checking).first&.name || "Primary Checking"
  end

  def collect_events
    events = []

    collect_expense_events(events)
    collect_income_events(events)

    # Sort by date, then income before expense on same day
    events.sort_by { |e| [e[:date], e[:event_type] == :income ? 0 : 1] }
  end

  def determine_event_type(item)
    category_name = item.budget_category&.name
    case category_name
    when "Savings" then :transfer
    when "Debt" then :debt_payoff
    else :expense
    end
  end

  def collect_expense_events(events)
    BudgetItem.joins(:budget_period).includes(:budget_category, :account)
      .where(expected_date: @start_date..@end_date)
      .find_each do |item|
        event_type = determine_event_type(item)
        from_label = item.account&.name || primary_checking_name
        to_label = item.name

        events << {
          date: item.expected_date,
          name: item.name,
          from_label: from_label,
          to_label: to_label,
          amount: -(item.planned_amount || 0).to_f,
          type: :expense,
          event_type: event_type,
          source: item.from_recurring? ? :recurring : :manual,
          record_type: "BudgetItem",
          record_id: item.id,
          budget_period_id: item.budget_period_id
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
          from_label: income.source_name,
          to_label: primary_checking_name,
          amount: (income.expected_amount || 0).to_f,
          type: :income,
          event_type: :income,
          source: income.recurring? ? :recurring : :manual,
          record_type: "Income",
          record_id: income.id,
          budget_period_id: income.budget_period_id
        }
      end
  end

  def build_timeline(events, starting_balance)
    running = starting_balance
    events.map do |event|
      running += event[:amount]
      rounded_balance = running.round(2)
      event.merge(
        running_balance: rounded_balance,
        is_negative: rounded_balance < 0
      )
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
end
