require "test_helper"

class ActionPlanGeneratorTest < ActiveSupport::TestCase
  setup do
    # Clean up any future periods beyond the fixture-defined ones
    # to ensure fresh state for each test
    BudgetPeriod.where("year = 2026 AND month >= 4").destroy_all
    # Also clean any auto-generated items in fixture periods
    budget_periods(:current_period).budget_items.where(auto_generated: true).destroy_all
    budget_periods(:current_period).incomes.where(auto_generated: true).destroy_all
    budget_periods(:draft_period).budget_items.where(auto_generated: true).destroy_all
    budget_periods(:draft_period).incomes.where(auto_generated: true).destroy_all

    @generator = ActionPlanGenerator.new(months_ahead: 3, from_date: Date.new(2026, 2, 21))
  end

  test "creates budget periods for current and future months" do
    # February and March already exist as fixtures; April should be created
    assert_nil BudgetPeriod.find_by(year: 2026, month: 4)

    @generator.generate!

    assert BudgetPeriod.find_by(year: 2026, month: 2), "February period should exist"
    assert BudgetPeriod.find_by(year: 2026, month: 3), "March period should exist"
    assert BudgetPeriod.find_by(year: 2026, month: 4), "April period should be created"
  end

  test "creates budget items from recurring expense transactions with correct attributes" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_items = march.budget_items.where(recurring_transaction: recurring_transactions(:rent_bill))

    assert_equal 1, rent_items.count, "Should create exactly one rent item for March"

    rent_item = rent_items.first
    assert_equal "Monthly Rent", rent_item.name
    assert_equal recurring_transactions(:rent_bill).amount, rent_item.planned_amount
    assert rent_item.auto_generated?, "Item should be marked as auto-generated"
  end

  test "creates income entries from recurring income transactions" do
    @generator.generate!

    march = budget_periods(:draft_period)
    auto_incomes = march.incomes.where(auto_generated: true)

    assert auto_incomes.any?, "Should create auto-generated income entries for March"

    # The recurring_paycheck is biweekly starting 2026-01-02, so it should have occurrences in March
    paycheck_txn = recurring_transactions(:recurring_paycheck)
    paycheck_incomes = auto_incomes.where(recurring_transaction_id: paycheck_txn.id)
    assert paycheck_incomes.any?, "Should create income entries from recurring paycheck transaction"

    income_entry = paycheck_incomes.first
    assert_equal "Employer Inc", income_entry.source_name
    assert_equal paycheck_txn.amount, income_entry.expected_amount
    assert income_entry.recurring?, "Auto-generated income should be marked as recurring"
    assert income_entry.auto_generated?, "Income should be marked as auto-generated"
  end

  test "does not duplicate existing items on re-run" do
    @generator.generate!

    item_count_before = BudgetItem.count
    income_count_before = Income.count

    @generator.generate!

    assert_equal item_count_before, BudgetItem.count, "Should not create duplicate budget items"
    assert_equal income_count_before, Income.count, "Should not create duplicate income entries"
  end

  test "regeneration replaces auto-generated items with fresh values" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_txn = recurring_transactions(:rent_bill)
    item = march.budget_items.where(recurring_transaction: rent_txn).first
    original_amount = rent_txn.amount

    # Simulate updating the recurring transaction amount
    rent_txn.update!(amount: 1600.00)

    @generator.generate!

    # The old item should be replaced with a new one reflecting the updated amount
    new_item = march.budget_items.where(recurring_transaction: rent_txn).first
    assert_equal 1600.00, new_item.planned_amount.to_f,
      "Regeneration should pick up the updated recurring transaction amount"
  ensure
    rent_txn&.update!(amount: original_amount)
  end

  test "sets expected_date from recurring transaction schedule" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_item = march.budget_items.where(recurring_transaction: recurring_transactions(:rent_bill)).first

    assert_not_nil rent_item.expected_date, "Expected date should be set"
    assert_equal 3, rent_item.expected_date.month, "Expected date should be in March"
    assert_equal 2026, rent_item.expected_date.year

    # Rent bill has start_date 2026-01-01, monthly, so March occurrence is 2026-03-01
    assert_equal Date.new(2026, 3, 1), rent_item.expected_date
  end

  test "sets budget_category from recurring transaction" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_item = march.budget_items.where(recurring_transaction: recurring_transactions(:rent_bill)).first

    assert_equal budget_categories(:housing), rent_item.budget_category,
      "Budget category should be set from the recurring transaction's category"

    electric_item = march.budget_items.where(recurring_transaction: recurring_transactions(:electric_bill)).first
    assert_equal budget_categories(:utilities), electric_item.budget_category,
      "Electric bill should use utilities category"
  end

  test "skips inactive recurring transactions" do
    @generator.generate!

    march = budget_periods(:draft_period)
    inactive_items = march.budget_items.where(recurring_transaction: recurring_transactions(:inactive_bill))

    assert_equal 0, inactive_items.count, "Should not create items for inactive transactions"
  end

  test "handles transactions with no budget_category by falling back to Personal" do
    # Create a transaction without a budget_category
    no_category_txn = RecurringTransaction.create!(
      name: "No Category Bill",
      amount: 25.00,
      due_day: 5,
      frequency: :monthly,
      start_date: Date.new(2026, 1, 5),
      direction: :expense,
      active: true
    )

    @generator.generate!

    march = budget_periods(:draft_period)
    items = march.budget_items.where(recurring_transaction: no_category_txn)

    assert_equal 1, items.count, "Should create item for transaction without category"
    assert_equal budget_categories(:personal), items.first.budget_category,
      "Should fall back to Personal category when transaction has no category"
  ensure
    no_category_txn&.destroy
  end

  test "annual transaction only appears in month with occurrence" do
    @generator.generate!

    # insurance_annual: start_date 2025-06-10, annual frequency
    # Next occurrence after 2025-06-10 is 2026-06-10
    # So February, March, April should NOT have this transaction
    february = budget_periods(:current_period)
    insurance_items_feb = february.budget_items.where(recurring_transaction: recurring_transactions(:insurance_annual))
    assert_equal 0, insurance_items_feb.count, "Annual transaction should not appear in February"

    march = budget_periods(:draft_period)
    insurance_items = march.budget_items.where(recurring_transaction: recurring_transactions(:insurance_annual))
    assert_equal 0, insurance_items.count, "Annual transaction should not appear in March"

    april = BudgetPeriod.find_by(year: 2026, month: 4)
    insurance_items_apr = april.budget_items.where(recurring_transaction: recurring_transactions(:insurance_annual))
    assert_equal 0, insurance_items_apr.count, "Annual transaction should not appear in April"
  end

  test "generates items across all covered months" do
    @generator.generate!

    # Rent is monthly, should appear in February, March, and April
    [2, 3, 4].each do |month|
      period = BudgetPeriod.find_by(year: 2026, month: month)
      assert_not_nil period, "Period for month #{month} should exist"

      rent_items = period.budget_items.where(recurring_transaction: recurring_transactions(:rent_bill), auto_generated: true)
      assert_equal 1, rent_items.count,
        "Should have exactly one auto-generated rent item in month #{month}"
    end
  end

  test "recalculates totals for each period" do
    @generator.generate!

    march = budget_periods(:draft_period).reload
    # After generation, total_planned should reflect the auto-generated items
    assert march.total_planned > 0, "Total planned should be recalculated with generated items"
  end
end
