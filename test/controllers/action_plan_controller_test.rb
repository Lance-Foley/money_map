# frozen_string_literal: true

require "test_helper"

class ActionPlanControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get show" do
    get action_plan_url
    assert_response :success
  end

  test "show with custom months parameter" do
    get action_plan_url, params: { months: 6 }
    assert_response :success
  end

  test "months parameter is clamped to valid range" do
    get action_plan_url, params: { months: 99 }
    assert_response :success
  end

  test "generate creates future period items" do
    post generate_action_plan_url
    assert_redirected_to action_plan_url(months: 3)
  end

  test "create_item adds budget item to specified period" do
    period = budget_periods(:draft_period)
    post action_plan_items_url, params: {
      budget_item: {
        budget_period_id: period.id,
        budget_category_id: budget_categories(:food).id,
        name: "Special Dinner",
        planned_amount: 75.00,
        expected_date: Date.new(2026, 3, 15)
      }
    }
    assert_redirected_to action_plan_url
    assert BudgetItem.find_by(name: "Special Dinner")
  end

  test "create_income adds income to specified period" do
    period = budget_periods(:draft_period)
    post action_plan_incomes_url, params: {
      income: {
        budget_period_id: period.id,
        source_name: "Bonus",
        expected_amount: 1000.00,
        pay_date: Date.new(2026, 3, 20)
      }
    }
    assert_redirected_to action_plan_url
  end

  test "update_item updates budget item amount" do
    item = budget_items(:rent)
    patch action_plan_item_url(item), params: {
      budget_item: { planned_amount: 1600.00 }
    }
    assert_redirected_to action_plan_url
    assert_equal 1600.00, item.reload.planned_amount.to_f
  end

  test "update_income updates income amount" do
    income = incomes(:main_paycheck)
    patch action_plan_income_url(income), params: {
      income: { expected_amount: 3000.00 }
    }
    assert_redirected_to action_plan_url
    assert_equal 3000.00, income.reload.expected_amount.to_f
  end

  test "should redirect to login when not authenticated" do
    reset!
    get action_plan_url
    assert_response :redirect
  end
end
