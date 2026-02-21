# frozen_string_literal: true

require "test_helper"

class BudgetFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "can view current month budget" do
    get budget_path
    assert_response :success
  end

  test "can view a specific month budget" do
    get budget_path(year: 2026, month: 2)
    assert_response :success
  end

  test "can create a budget item" do
    period = budget_periods(:current_period)
    category = budget_categories(:food)

    assert_difference("BudgetItem.count") do
      post budget_items_path, params: {
        budget_item: {
          budget_period_id: period.id,
          budget_category_id: category.id,
          name: "Dining Out",
          planned_amount: 200
        }
      }
    end
    assert_response :redirect
    assert BudgetItem.exists?(name: "Dining Out")
  end

  test "can update a budget item" do
    item = budget_items(:groceries)
    patch budget_item_path(item), params: {
      budget_item: { planned_amount: 700 }
    }
    assert_response :redirect
    item.reload
    assert_equal 700, item.planned_amount.to_i
  end
end
