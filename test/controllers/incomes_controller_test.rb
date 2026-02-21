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
end
