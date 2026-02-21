require "test_helper"

class BudgetPeriodTest < ActiveSupport::TestCase
  test "valid budget period" do
    period = BudgetPeriod.new(year: 2025, month: 6)
    assert period.valid?
  end

  test "requires year" do
    period = BudgetPeriod.new(month: 6)
    assert_not period.valid?
    assert_includes period.errors[:year], "can't be blank"
  end

  test "requires month" do
    period = BudgetPeriod.new(year: 2025)
    assert_not period.valid?
    assert_includes period.errors[:month], "can't be blank"
  end

  test "month must be between 1 and 12" do
    assert_not BudgetPeriod.new(year: 2025, month: 0).valid?
    assert_not BudgetPeriod.new(year: 2025, month: 13).valid?
    assert BudgetPeriod.new(year: 2025, month: 1).valid?
    assert BudgetPeriod.new(year: 2025, month: 12).valid?
  end

  test "year and month combination must be unique" do
    existing = budget_periods(:current_period)
    duplicate = BudgetPeriod.new(year: existing.year, month: existing.month)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:year], "has already been taken"
  end

  test "status defaults to draft" do
    period = BudgetPeriod.create!(year: 2025, month: 6)
    assert period.draft?
  end

  test "left_to_budget returns income minus planned" do
    period = budget_periods(:current_period)
    expected = period.total_income - period.total_planned
    assert_equal expected, period.left_to_budget
  end

  test "zero_based? returns true when left_to_budget is zero" do
    period = budget_periods(:last_month)
    assert period.zero_based?
  end

  test "zero_based? returns false when there is money left" do
    period = budget_periods(:current_period)
    assert_not period.zero_based?
  end

  test "display_name formats month and year" do
    period = budget_periods(:current_period)
    assert_equal "February 2026", period.display_name
  end

  test "chronological scope orders by year then month" do
    periods = BudgetPeriod.chronological
    years_months = periods.map { |p| [p.year, p.month] }
    assert_equal years_months, years_months.sort
  end

  test "enum values are correct" do
    assert_equal "draft", BudgetPeriod.new(status: 0).status
    assert_equal "active", BudgetPeriod.new(status: 1).status
    assert_equal "closed", BudgetPeriod.new(status: 2).status
  end

  test "copy_from creates budget items from another period" do
    source = budget_periods(:last_month)
    target = budget_periods(:draft_period)

    assert_difference "target.budget_items.count", source.budget_items.count do
      target.copy_from(source)
    end
  end

  test "recalculate_totals! updates totals from incomes and items" do
    period = budget_periods(:current_period)
    period.recalculate_totals!
    period.reload

    assert_equal period.incomes.sum(:received_amount), period.total_income
    assert_equal period.budget_items.sum(:planned_amount), period.total_planned
    assert_equal period.budget_items.sum(:spent_amount), period.total_spent
  end
end
