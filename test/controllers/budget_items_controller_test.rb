# frozen_string_literal: true

require "test_helper"

class BudgetItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @period = budget_periods(:current_period)
    @category = budget_categories(:food)
    @item = budget_items(:groceries)
  end

  test "should create budget item with valid params" do
    assert_difference("BudgetItem.count") do
      post budget_items_url, params: {
        budget_item: {
          budget_period_id: @period.id,
          budget_category_id: @category.id,
          name: "Dining Out",
          planned_amount: 200.00
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end

  test "should not create budget item with invalid params" do
    assert_no_difference("BudgetItem.count") do
      post budget_items_url, params: {
        budget_item: {
          budget_period_id: @period.id,
          budget_category_id: @category.id,
          name: "",
          planned_amount: 200.00
        }
      }
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end

  test "should update budget item" do
    patch budget_item_url(@item), params: { budget_item: { planned_amount: 700.00 } }
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
    @item.reload
    assert_equal 700.00, @item.planned_amount.to_f
  end

  test "should destroy budget item" do
    assert_difference("BudgetItem.count", -1) do
      delete budget_item_url(@item)
    end
    assert_redirected_to budget_path(year: @period.year, month: @period.month)
  end
end
