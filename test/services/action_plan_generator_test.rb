require "test_helper"

class ActionPlanGeneratorTest < ActiveSupport::TestCase
  setup do
    # Clean up any future periods beyond the fixture-defined ones
    # to ensure fresh state for each test
    BudgetPeriod.where("year = 2026 AND month >= 4").destroy_all
    # Also clean any auto-generated items in the March draft period
    budget_periods(:draft_period).budget_items.where(auto_generated: true).destroy_all
    budget_periods(:draft_period).incomes.where(auto_generated: true).destroy_all

    @generator = ActionPlanGenerator.new(months_ahead: 3, from_date: Date.new(2026, 2, 21))
  end

  test "creates budget periods for future months" do
    # March already exists as draft_period fixture; April and May should be created
    assert_nil BudgetPeriod.find_by(year: 2026, month: 4)
    assert_nil BudgetPeriod.find_by(year: 2026, month: 5)

    @generator.generate!

    assert BudgetPeriod.find_by(year: 2026, month: 3), "March period should exist"
    assert BudgetPeriod.find_by(year: 2026, month: 4), "April period should be created"
    assert BudgetPeriod.find_by(year: 2026, month: 5), "May period should be created"
  end

  test "creates budget items from recurring bills with correct attributes" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_items = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill))

    assert_equal 1, rent_items.count, "Should create exactly one rent item for March"

    rent_item = rent_items.first
    assert_equal "Monthly Rent", rent_item.name
    assert_equal recurring_bills(:rent_bill).amount, rent_item.planned_amount
    assert rent_item.auto_generated?, "Item should be marked as auto-generated"
  end

  test "creates income entries from recurring income" do
    @generator.generate!

    march = budget_periods(:draft_period)
    auto_incomes = march.incomes.where(auto_generated: true)

    assert auto_incomes.any?, "Should create auto-generated income entries for March"

    # The main_paycheck is biweekly starting 2026-01-02, so it should have occurrences in March
    main_source_incomes = auto_incomes.where(recurring_source_id: incomes(:main_paycheck).id)
    assert main_source_incomes.any?, "Should create income entries from main paycheck source"

    income_entry = main_source_incomes.first
    assert_equal "Employer Inc", income_entry.source_name
    assert_equal incomes(:main_paycheck).expected_amount, income_entry.expected_amount
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

  test "does not overwrite edited items" do
    @generator.generate!

    march = budget_periods(:draft_period)
    item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    item.update!(planned_amount: 1600.00)

    @generator.generate!

    item.reload
    assert_equal 1600.00, item.planned_amount.to_f,
      "User-edited amount should be preserved after regeneration"
  end

  test "sets expected_date from recurring bill schedule" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first

    assert_not_nil rent_item.expected_date, "Expected date should be set"
    assert_equal 3, rent_item.expected_date.month, "Expected date should be in March"
    assert_equal 2026, rent_item.expected_date.year

    # Rent bill has start_date 2026-01-01, monthly, so March occurrence is 2026-03-01
    assert_equal Date.new(2026, 3, 1), rent_item.expected_date
  end

  test "sets budget_category from recurring bill" do
    @generator.generate!

    march = budget_periods(:draft_period)
    rent_item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first

    assert_equal budget_categories(:housing), rent_item.budget_category,
      "Budget category should be set from the recurring bill's category"

    electric_item = march.budget_items.where(recurring_bill: recurring_bills(:electric_bill)).first
    assert_equal budget_categories(:utilities), electric_item.budget_category,
      "Electric bill should use utilities category"
  end

  test "skips inactive recurring bills" do
    @generator.generate!

    march = budget_periods(:draft_period)
    inactive_items = march.budget_items.where(recurring_bill: recurring_bills(:inactive_bill))

    assert_equal 0, inactive_items.count, "Should not create items for inactive bills"
  end

  test "handles bills with no budget_category by falling back to Personal" do
    # Create a bill without a budget_category
    no_category_bill = RecurringBill.create!(
      name: "No Category Bill",
      amount: 25.00,
      due_day: 5,
      frequency: :monthly,
      start_date: Date.new(2026, 1, 5),
      active: true
    )

    @generator.generate!

    march = budget_periods(:draft_period)
    items = march.budget_items.where(recurring_bill: no_category_bill)

    assert_equal 1, items.count, "Should create item for bill without category"
    assert_equal budget_categories(:personal), items.first.budget_category,
      "Should fall back to Personal category when bill has no category"
  ensure
    no_category_bill&.destroy
  end

  test "annual bill only appears in month with occurrence" do
    @generator.generate!

    # insurance_annual: start_date 2025-06-10, annual frequency
    # Next occurrence after 2025-06-10 is 2026-06-10
    # So March, April, May should NOT have this bill
    march = budget_periods(:draft_period)
    insurance_items = march.budget_items.where(recurring_bill: recurring_bills(:insurance_annual))
    assert_equal 0, insurance_items.count, "Annual bill should not appear in March"

    april = BudgetPeriod.find_by(year: 2026, month: 4)
    insurance_items_apr = april.budget_items.where(recurring_bill: recurring_bills(:insurance_annual))
    assert_equal 0, insurance_items_apr.count, "Annual bill should not appear in April"

    may = BudgetPeriod.find_by(year: 2026, month: 5)
    insurance_items_may = may.budget_items.where(recurring_bill: recurring_bills(:insurance_annual))
    assert_equal 0, insurance_items_may.count, "Annual bill should not appear in May"
  end

  test "generates items across all future months" do
    @generator.generate!

    # Rent bill is monthly, should appear in March, April, and May
    [3, 4, 5].each do |month|
      period = BudgetPeriod.find_by(year: 2026, month: month)
      assert_not_nil period, "Period for month #{month} should exist"

      rent_items = period.budget_items.where(recurring_bill: recurring_bills(:rent_bill))
      assert_equal 1, rent_items.count,
        "Should have exactly one rent item in month #{month}"
    end
  end

  test "recalculates totals for each period" do
    @generator.generate!

    march = budget_periods(:draft_period).reload
    # After generation, total_planned should reflect the auto-generated items
    assert march.total_planned > 0, "Total planned should be recalculated with generated items"
  end
end
