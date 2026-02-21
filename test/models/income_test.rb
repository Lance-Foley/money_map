require "test_helper"

class IncomeTest < ActiveSupport::TestCase
  test "valid income" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Side Job",
      expected_amount: 1000.00
    )
    assert income.valid?
  end

  test "requires source_name" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      expected_amount: 1000.00
    )
    assert_not income.valid?
    assert_includes income.errors[:source_name], "can't be blank"
  end

  test "requires expected_amount" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Side Job"
    )
    assert_not income.valid?
    assert_includes income.errors[:expected_amount], "can't be blank"
  end

  test "expected_amount must be greater than 0" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Side Job",
      expected_amount: 0
    )
    assert_not income.valid?
    assert_includes income.errors[:expected_amount], "must be greater than 0"
  end

  test "requires budget_period" do
    income = Income.new(source_name: "Side Job", expected_amount: 1000.00)
    assert_not income.valid?
    assert_includes income.errors[:budget_period], "must exist"
  end

  test "received? returns true when received_amount is positive" do
    income = incomes(:main_paycheck)
    assert income.received?
  end

  test "received? returns false when received_amount is nil" do
    income = incomes(:freelance_income)
    assert_not income.received?
  end

  test "received? returns false when received_amount is zero" do
    income = Income.new(received_amount: 0)
    assert_not income.received?
  end

  # --- Expanded frequency enum ---

  test "expanded enum values are correct" do
    assert_equal "weekly", Income.new(frequency: 0).frequency
    assert_equal "biweekly", Income.new(frequency: 1).frequency
    assert_equal "semimonthly", Income.new(frequency: 2).frequency
    assert_equal "monthly", Income.new(frequency: 3).frequency
    assert_equal "quarterly", Income.new(frequency: 4).frequency
    assert_equal "semi_annual", Income.new(frequency: 5).frequency
    assert_equal "annual", Income.new(frequency: 6).frequency
    assert_equal "custom", Income.new(frequency: 7).frequency
  end

  # --- Custom frequency validations ---

  test "custom frequency requires interval fields" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Test",
      expected_amount: 100,
      frequency: :custom,
      recurring: true
    )
    assert_not income.valid?
    assert_includes income.errors[:custom_interval_value], "can't be blank"
    assert_includes income.errors[:custom_interval_unit], "can't be blank"
  end

  test "custom frequency with interval fields is valid" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Test",
      expected_amount: 100,
      frequency: :custom,
      recurring: true,
      start_date: Date.current,
      custom_interval_value: 6,
      custom_interval_unit: 1
    )
    assert income.valid?
  end

  test "custom_interval_value must be greater than 0" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Test",
      expected_amount: 100,
      frequency: :custom,
      recurring: true,
      start_date: Date.current,
      custom_interval_value: 0,
      custom_interval_unit: 1
    )
    assert_not income.valid?
    assert_includes income.errors[:custom_interval_value], "must be greater than 0"
  end

  test "non-custom frequency does not require interval fields" do
    income = Income.new(
      budget_period: budget_periods(:current_period),
      source_name: "Test",
      expected_amount: 100,
      frequency: :monthly
    )
    assert income.valid?
  end

  # --- recurring_sources scope ---

  test "recurring_sources scope returns non-generated recurring income" do
    sources = Income.recurring_sources
    assert sources.all? { |i| i.recurring? && !i.auto_generated? }
    assert_includes sources, incomes(:main_paycheck)
    assert_includes sources, incomes(:second_paycheck)
    assert_not_includes sources, incomes(:freelance_income)
  end

  # --- recurring defaults ---

  test "recurring defaults to false" do
    income = Income.create!(
      budget_period: budget_periods(:draft_period),
      source_name: "Test Income",
      expected_amount: 500.00
    )
    assert_not income.recurring?
  end
end
