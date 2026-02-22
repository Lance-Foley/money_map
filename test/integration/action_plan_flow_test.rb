# frozen_string_literal: true

require "test_helper"

class ActionPlanFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "view action plan with generated future months" do
    get action_plan_url
    assert_response :success
  end

  test "view action plan with custom month range" do
    get action_plan_url, params: { months: 6 }
    assert_response :success
  end

  test "add one-off expense to future month" do
    period = BudgetPeriod.find_or_create_by!(year: 2026, month: 4)

    assert_difference("BudgetItem.count") do
      post action_plan_items_url, params: {
        budget_item: {
          budget_period_id: period.id,
          budget_category_id: budget_categories(:food).id,
          name: "Birthday Dinner",
          planned_amount: 120.00,
          expected_date: Date.new(2026, 4, 15)
        }
      }
    end
    assert_redirected_to action_plan_url

    item = BudgetItem.find_by(name: "Birthday Dinner")
    assert_not_nil item
    assert_equal 120.00, item.planned_amount.to_f
    assert_equal Date.new(2026, 4, 15), item.expected_date
    assert_not item.auto_generated?
  end

  test "edit generated item amount for one month only" do
    # Generate future months starting from next month
    ActionPlanGenerator.new(months_ahead: 3).generate!

    # Find a generated rent item for a future month
    future_periods = BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").chronological
    generated_item = nil
    target_period = nil

    future_periods.each do |period|
      generated_item = period.budget_items.where(
        recurring_transaction: recurring_transactions(:rent_bill),
        auto_generated: true
      ).first
      if generated_item
        target_period = period
        break
      end
    end

    skip("No auto-generated rent items found in future months") unless generated_item

    original_amount = generated_item.planned_amount

    patch action_plan_item_url(generated_item), params: {
      budget_item: { planned_amount: 1700.00 }
    }

    generated_item.reload
    assert_equal 1700.00, generated_item.planned_amount.to_f

    # Other months' generated items should still have the original amount
    other_periods = future_periods.where.not(id: target_period.id)
    other_periods.each do |period|
      other_item = period.budget_items.where(
        recurring_transaction: recurring_transactions(:rent_bill),
        auto_generated: true
      ).first
      next unless other_item
      assert_equal original_amount.to_f, other_item.planned_amount.to_f,
        "Item in #{period.display_name} should still have original amount"
    end
  end

  test "regenerate does not overwrite edited items" do
    ActionPlanGenerator.new(months_ahead: 3).generate!

    future_periods = BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").chronological
    item = nil
    future_periods.each do |period|
      item = period.budget_items.where(auto_generated: true).first
      break if item
    end

    skip("No auto-generated items found") unless item

    # Edit the item's amount
    item.update!(planned_amount: 1700.00)

    # Regenerate should not overwrite
    post generate_action_plan_url
    assert_redirected_to action_plan_url(months: 3)

    item.reload
    assert_equal 1700.00, item.planned_amount.to_f,
      "Regeneration should not overwrite user-edited amounts"
  end

  test "action plan shows cash flow data" do
    get action_plan_url
    assert_response :success
  end

  test "add income to future month" do
    period = BudgetPeriod.find_or_create_by!(year: 2026, month: 4)

    assert_difference("Income.count") do
      post action_plan_incomes_url, params: {
        income: {
          budget_period_id: period.id,
          source_name: "Tax Refund",
          expected_amount: 2000.00,
          pay_date: Date.new(2026, 4, 10)
        }
      }
    end
    assert_redirected_to action_plan_url

    income = Income.find_by(source_name: "Tax Refund")
    assert_not_nil income
    assert_equal 2000.00, income.expected_amount.to_f
  end

  test "generator creates items from recurring transactions with different frequencies" do
    ActionPlanGenerator.new(months_ahead: 3).generate!

    # Monthly rent should appear in every future month
    future_periods = BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").chronological
    future_periods.each do |period|
      rent_items = period.budget_items.where(recurring_transaction: recurring_transactions(:rent_bill))
      assert rent_items.any?,
        "Rent transaction should generate an item for #{period.display_name}"
    end
  end

  test "generator skips inactive recurring transactions" do
    ActionPlanGenerator.new(months_ahead: 3).generate!

    future_periods = BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").chronological
    future_periods.each do |period|
      inactive_items = period.budget_items.where(recurring_transaction: recurring_transactions(:inactive_bill))
      assert_equal 0, inactive_items.count,
        "Inactive transaction should not generate items for #{period.display_name}"
    end
  end

  test "generated items have correct expected_date and category" do
    ActionPlanGenerator.new(months_ahead: 3).generate!

    future_period = BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").chronological.first
    skip("No future period found") unless future_period

    rent_item = future_period.budget_items.where(
      recurring_transaction: recurring_transactions(:rent_bill),
      auto_generated: true
    ).first
    skip("No auto-generated rent item found") unless rent_item

    assert_not_nil rent_item.expected_date
    assert_equal future_period.month, rent_item.expected_date.month
    assert_equal recurring_transactions(:rent_bill).budget_category, rent_item.budget_category
    assert_equal recurring_transactions(:rent_bill).amount.to_f, rent_item.planned_amount.to_f
  end
end
