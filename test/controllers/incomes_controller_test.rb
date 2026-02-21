# frozen_string_literal: true

require "test_helper"

class IncomesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @period = budget_periods(:current_period)
    @income = incomes(:main_paycheck)
  end

  test "should create income with valid params" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Side Gig",
          expected_amount: 300.00,
          frequency: "monthly"
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end

  test "should not create income with invalid params" do
    assert_no_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "",
          expected_amount: nil
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end

  test "should update income" do
    patch income_url(@income), params: { income: { received_amount: 2600.00 } }
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    @income.reload
    assert_equal 2600.00, @income.received_amount.to_f
  end

  test "should destroy income" do
    assert_difference("Income.count", -1) do
      delete income_url(@income)
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end

  test "should create income with weekly frequency" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Weekly Gig",
          expected_amount: 200.00,
          frequency: "weekly",
          start_date: "2026-02-01",
          recurring: true
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    income = Income.last
    assert_equal "weekly", income.frequency
    assert_equal Date.new(2026, 2, 1), income.start_date
    assert income.recurring?
  end

  test "should create income with biweekly frequency and start_date" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Biweekly Paycheck",
          expected_amount: 1800.00,
          frequency: "biweekly",
          start_date: "2026-01-05",
          pay_date: "2026-02-16",
          recurring: true
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    income = Income.last
    assert_equal "biweekly", income.frequency
    assert_equal Date.new(2026, 1, 5), income.start_date
  end

  test "should create income with quarterly frequency" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Quarterly Dividend",
          expected_amount: 500.00,
          frequency: "quarterly",
          start_date: "2026-01-15",
          recurring: true
        }
      }
    end
    income = Income.last
    assert_equal "quarterly", income.frequency
  end

  test "should create income with annual frequency" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Annual Bonus",
          expected_amount: 5000.00,
          frequency: "annual",
          start_date: "2026-12-15",
          recurring: true
        }
      }
    end
    income = Income.last
    assert_equal "annual", income.frequency
  end

  test "should create income with custom frequency" do
    assert_difference("Income.count") do
      post incomes_url, params: {
        income: {
          budget_period_id: @period.id,
          source_name: "Custom Contract",
          expected_amount: 1500.00,
          frequency: "custom",
          start_date: "2026-02-01",
          custom_interval_value: 6,
          custom_interval_unit: 1,
          recurring: true
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    income = Income.last
    assert_equal "custom", income.frequency
    assert_equal 6, income.custom_interval_value
    assert_equal 1, income.custom_interval_unit
  end

  test "should update income frequency and start_date" do
    patch income_url(@income), params: {
      income: {
        frequency: "weekly",
        start_date: "2026-03-01"
      }
    }
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    @income.reload
    assert_equal "weekly", @income.frequency
    assert_equal Date.new(2026, 3, 1), @income.start_date
  end

  test "should update income to custom frequency with interval fields" do
    patch income_url(@income), params: {
      income: {
        frequency: "custom",
        custom_interval_value: 3,
        custom_interval_unit: 2,
        start_date: "2026-01-01"
      }
    }
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    @income.reload
    assert_equal "custom", @income.frequency
    assert_equal 3, @income.custom_interval_value
    assert_equal 2, @income.custom_interval_unit
  end
end
