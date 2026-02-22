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

  # --- recurring_transaction association ---

  test "belongs to recurring_transaction optionally" do
    income = incomes(:main_paycheck)
    assert_not_nil income.recurring_transaction
    assert_equal recurring_transactions(:recurring_paycheck), income.recurring_transaction
  end

  test "income without recurring_transaction is valid" do
    income = incomes(:freelance_income)
    assert_nil income.recurring_transaction
    assert income.valid?
  end
end
