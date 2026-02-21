require "test_helper"

class CashFlowCalculatorTest < ActiveSupport::TestCase
  setup do
    @start_date = Date.new(2026, 2, 1)
    @end_date = Date.new(2026, 2, 28)
    @calculator = CashFlowCalculator.new(@start_date, @end_date)
  end

  # -- Starting balance --

  test "starting_balance uses current checking and savings account balances" do
    result = @calculator.calculate
    expected = Account.active.where(account_type: [:checking, :savings]).sum(:balance).to_f
    assert_equal expected, result[:starting_balance]
  end

  # -- Timeline structure and ordering --

  test "returns timeline with chronological events" do
    result = @calculator.calculate
    assert result[:timeline].is_a?(Array)
    dates = result[:timeline].map { |e| e[:date] }
    assert_equal dates.sort, dates
  end

  test "events sorted by date then type with income before expense on same day" do
    # Move electric bill expected_date to Feb 14 to match main_paycheck pay_date
    budget_items(:electric).update_columns(expected_date: Date.new(2026, 2, 14))

    result = @calculator.calculate
    timeline = result[:timeline]

    # Find events on Feb 14 (now has both income and expense)
    feb14_events = timeline.select { |e| e[:date] == Date.new(2026, 2, 14) }
    assert feb14_events.length >= 2, "Should have both income and expense on Feb 14"

    types = feb14_events.map { |e| e[:type] }
    income_indices = types.each_index.select { |i| types[i] == :income }
    expense_indices = types.each_index.select { |i| types[i] == :expense }

    assert income_indices.any?, "Should have income on Feb 14"
    assert expense_indices.any?, "Should have expense on Feb 14"
    assert income_indices.max < expense_indices.min,
      "Income events should come before expense events on the same day"
  end

  # -- Income events --

  test "income events have positive amounts" do
    result = @calculator.calculate
    income_events = result[:timeline].select { |e| e[:type] == :income }
    assert income_events.any?, "Should have at least one income event"
    assert income_events.all? { |e| e[:amount] > 0 },
      "All income events should have positive amounts"
  end

  # -- Expense events --

  test "expense events have negative amounts" do
    result = @calculator.calculate
    expense_events = result[:timeline].select { |e| e[:type] == :expense }
    assert expense_events.any?, "Should have at least one expense event"
    assert expense_events.all? { |e| e[:amount] < 0 },
      "All expense events should have negative amounts"
  end

  # -- Running balance --

  test "running_balance tracks cumulative effect" do
    result = @calculator.calculate
    timeline = result[:timeline]
    return if timeline.empty?

    running = result[:starting_balance]
    timeline.each do |event|
      running += event[:amount]
      assert_equal running.round(2), event[:running_balance],
        "Running balance mismatch for #{event[:name]} on #{event[:date]}"
    end
  end

  # -- Negative balance dates --

  test "flags negative balance dates" do
    result = @calculator.calculate
    assert result.key?(:negative_dates)
    assert result[:negative_dates].is_a?(Array)
  end

  test "negative_dates contains dates where running balance goes below zero" do
    # With our fixtures, starting balance is 17500, so no negatives expected
    result = @calculator.calculate
    negative_events = result[:timeline].select { |e| e[:running_balance] < 0 }
    assert_equal negative_events.map { |e| e[:date] }.uniq, result[:negative_dates]
  end

  # -- Monthly summary --

  test "monthly_summary contains totals per month" do
    calculator = CashFlowCalculator.new(Date.new(2026, 2, 1), Date.new(2026, 2, 28))
    result = calculator.calculate
    assert result[:monthly_summary].is_a?(Array)
    assert result[:monthly_summary].any?, "Should have at least one month in summary"

    result[:monthly_summary].each do |month|
      assert month.key?(:year)
      assert month.key?(:month)
      assert month.key?(:display_name)
      assert month.key?(:total_income)
      assert month.key?(:total_expenses)
      assert month.key?(:surplus)
      assert month.key?(:ending_balance)
    end
  end

  test "monthly_summary calculates correct totals for February" do
    result = @calculator.calculate
    feb_summary = result[:monthly_summary].find { |m| m[:month] == 2 && m[:year] == 2026 }
    assert_not_nil feb_summary, "Should have a February 2026 summary"

    assert_equal "February 2026", feb_summary[:display_name]

    # Income from fixtures in Feb range: main_paycheck(2500) + second_paycheck(2500) + freelance(500)
    income_events = result[:timeline].select { |e| e[:type] == :income && e[:date].month == 2 }
    expected_income = income_events.sum { |e| e[:amount] }
    assert_equal expected_income.round(2), feb_summary[:total_income]

    # Expenses from fixtures in Feb range: rent(1500) + groceries(600) + electric(150) + christmas_fund(100)
    expense_events = result[:timeline].select { |e| e[:type] == :expense && e[:date].month == 2 }
    expected_expenses = expense_events.sum { |e| e[:amount].abs }
    assert_equal expected_expenses.round(2), feb_summary[:total_expenses]

    assert_equal (feb_summary[:total_income] - feb_summary[:total_expenses]).round(2), feb_summary[:surplus]
  end

  # -- Empty range --

  test "empty range returns empty timeline" do
    # Use a date range with no budget items or incomes
    calculator = CashFlowCalculator.new(Date.new(2030, 1, 1), Date.new(2030, 1, 31))
    result = calculator.calculate

    assert_equal [], result[:timeline]
    assert_equal [], result[:negative_dates]
    assert_equal [], result[:monthly_summary]
    assert result[:starting_balance].is_a?(Numeric)
  end

  # -- Chart data --

  test "chart_data has matching labels and data arrays" do
    result = @calculator.calculate
    assert result[:chart_data].key?(:labels)
    assert result[:chart_data].key?(:data)
    assert_equal result[:chart_data][:labels].length, result[:chart_data][:data].length
  end

  test "chart_data is empty when timeline is empty" do
    calculator = CashFlowCalculator.new(Date.new(2030, 1, 1), Date.new(2030, 1, 31))
    result = calculator.calculate
    assert_equal [], result[:chart_data][:labels]
    assert_equal [], result[:chart_data][:data]
  end

  test "chart_data includes starting balance as first point" do
    result = @calculator.calculate
    return if result[:timeline].empty?

    assert_equal result[:starting_balance], result[:chart_data][:data].first
  end

  # -- Event record metadata --

  test "timeline events include record metadata" do
    result = @calculator.calculate
    return if result[:timeline].empty?

    result[:timeline].each do |event|
      assert event.key?(:date), "Event should have :date"
      assert event.key?(:name), "Event should have :name"
      assert event.key?(:amount), "Event should have :amount"
      assert event.key?(:type), "Event should have :type"
      assert event.key?(:source), "Event should have :source"
      assert event.key?(:record_type), "Event should have :record_type"
      assert event.key?(:record_id), "Event should have :record_id"
      assert event.key?(:running_balance), "Event should have :running_balance"
    end
  end

  test "expense events have BudgetItem record_type" do
    result = @calculator.calculate
    expense_events = result[:timeline].select { |e| e[:type] == :expense }
    assert expense_events.all? { |e| e[:record_type] == "BudgetItem" }
  end

  test "income events have Income record_type" do
    result = @calculator.calculate
    income_events = result[:timeline].select { |e| e[:type] == :income }
    assert income_events.all? { |e| e[:record_type] == "Income" }
  end
end
