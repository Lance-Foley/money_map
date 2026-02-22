require "test_helper"

class RecurringTransactionTest < ActiveSupport::TestCase
  test "valid recurring transaction" do
    txn = RecurringTransaction.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert txn.valid?
  end

  test "requires name" do
    txn = RecurringTransaction.new(amount: 15.99, due_day: 15)
    assert_not txn.valid?
    assert_includes txn.errors[:name], "can't be blank"
  end

  test "requires amount" do
    txn = RecurringTransaction.new(name: "Netflix", due_day: 15)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "can't be blank"
  end

  test "amount must be greater than 0" do
    txn = RecurringTransaction.new(name: "Netflix", amount: 0, due_day: 15)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "must be greater than 0"
  end

  test "requires due_day" do
    txn = RecurringTransaction.new(name: "Netflix", amount: 15.99)
    assert_not txn.valid?
    assert_includes txn.errors[:due_day], "can't be blank"
  end

  test "due_day must be between 1 and 31" do
    assert_not RecurringTransaction.new(name: "Test", amount: 10, due_day: 0).valid?
    assert_not RecurringTransaction.new(name: "Test", amount: 10, due_day: 32).valid?
    assert RecurringTransaction.new(name: "Test", amount: 10, due_day: 1).valid?
    assert RecurringTransaction.new(name: "Test", amount: 10, due_day: 31).valid?
  end

  test "account is optional" do
    txn = RecurringTransaction.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert txn.valid?
  end

  test "budget_category is optional" do
    txn = RecurringTransaction.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert txn.valid?
  end

  test "active defaults to true" do
    txn = RecurringTransaction.create!(name: "Netflix", amount: 15.99, due_day: 15)
    assert txn.active?
  end

  test "auto_create_transaction defaults to false" do
    txn = RecurringTransaction.create!(name: "Netflix", amount: 15.99, due_day: 15)
    assert_not txn.auto_create_transaction?
  end

  test "direction defaults to expense" do
    txn = RecurringTransaction.create!(name: "Netflix", amount: 15.99, due_day: 15)
    assert txn.expense?
  end

  test "direction can be income" do
    txn = RecurringTransaction.create!(name: "Paycheck", amount: 2500, due_day: 1, direction: :income)
    assert txn.income?
  end

  test "direction can be transfer" do
    txn = RecurringTransaction.create!(name: "Savings", amount: 500, due_day: 1, direction: :transfer)
    assert txn.transfer?
  end

  test "active scope returns only active transactions" do
    active = RecurringTransaction.active
    assert active.include?(recurring_transactions(:rent_bill))
    assert_not active.include?(recurring_transactions(:inactive_bill))
  end

  test "expenses scope returns only expense direction" do
    expenses = RecurringTransaction.expenses
    assert expenses.all?(&:expense?)
  end

  test "incomes_only scope returns only income direction" do
    incomes = RecurringTransaction.incomes_only
    assert incomes.all?(&:income?)
    assert incomes.include?(recurring_transactions(:recurring_paycheck))
  end

  test "overdue? returns true when next_due_date is in the past" do
    txn = recurring_transactions(:inactive_bill)
    assert txn.overdue?
  end

  test "overdue? returns false when next_due_date is in the future" do
    txn = recurring_transactions(:rent_bill)
    assert_not txn.overdue?
  end

  test "overdue? returns false when next_due_date is nil" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 15)
    txn.next_due_date = nil
    assert_not txn.overdue?
  end

  test "days_until_due calculates correctly" do
    txn = recurring_transactions(:rent_bill)
    expected = (txn.next_due_date - Date.current).to_i
    assert_equal expected, txn.days_until_due
  end

  test "days_until_due returns nil when no next_due_date" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 15)
    txn.next_due_date = nil
    assert_nil txn.days_until_due
  end

  test "calculate_next_due_date sets date on create" do
    txn = RecurringTransaction.create!(name: "New Bill", amount: 99.99, due_day: 25)
    assert_not_nil txn.next_due_date
  end

  # --- Expanded frequency enum ---

  test "expanded enum values are correct" do
    assert_equal "weekly", RecurringTransaction.new(frequency: 0).frequency
    assert_equal "biweekly", RecurringTransaction.new(frequency: 1).frequency
    assert_equal "semimonthly", RecurringTransaction.new(frequency: 2).frequency
    assert_equal "monthly", RecurringTransaction.new(frequency: 3).frequency
    assert_equal "quarterly", RecurringTransaction.new(frequency: 4).frequency
    assert_equal "semi_annual", RecurringTransaction.new(frequency: 5).frequency
    assert_equal "annual", RecurringTransaction.new(frequency: 6).frequency
    assert_equal "custom", RecurringTransaction.new(frequency: 7).frequency
  end

  # --- Custom frequency validations ---

  test "custom frequency requires interval fields" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 1, frequency: :custom, start_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:custom_interval_value], "can't be blank"
    assert_includes txn.errors[:custom_interval_unit], "can't be blank"
  end

  test "custom frequency with interval is valid" do
    txn = RecurringTransaction.new(
      name: "Test", amount: 10, due_day: 1, frequency: :custom,
      start_date: Date.current, custom_interval_value: 6, custom_interval_unit: 1
    )
    assert txn.valid?
  end

  test "custom_interval_value must be greater than 0" do
    txn = RecurringTransaction.new(
      name: "Test", amount: 10, due_day: 1, frequency: :custom,
      start_date: Date.current, custom_interval_value: 0, custom_interval_unit: 1
    )
    assert_not txn.valid?
    assert_includes txn.errors[:custom_interval_value], "must be greater than 0"
  end

  test "non-custom frequency does not require interval fields" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 1, frequency: :monthly)
    assert txn.valid?
  end

  # --- Schedulable integration: schedule_description ---

  test "schedule_description returns human readable string for monthly" do
    txn = recurring_transactions(:rent_bill)
    assert_equal "Monthly on the 1st", txn.schedule_description
  end

  test "schedule_description returns human readable string for annual" do
    txn = recurring_transactions(:insurance_annual)
    assert_equal "Annually on June 10", txn.schedule_description
  end

  # --- Schedulable integration: occurrences_in_range ---

  test "occurrences_in_range returns dates for monthly transaction" do
    txn = recurring_transactions(:rent_bill)
    dates = txn.occurrences_in_range(Date.new(2026, 3, 1), Date.new(2026, 5, 31))
    assert_equal 3, dates.length
    assert_equal [Date.new(2026, 3, 1), Date.new(2026, 4, 1), Date.new(2026, 5, 1)], dates
  end

  test "occurrences_in_range returns dates for annual transaction" do
    txn = recurring_transactions(:insurance_annual)
    dates = txn.occurrences_in_range(Date.new(2026, 1, 1), Date.new(2026, 12, 31))
    assert_equal 1, dates.length
    assert_equal Date.new(2026, 6, 10), dates.first
  end

  # --- start_date auto-set from due_day ---

  test "start_date auto-set from due_day if blank" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 15, frequency: :monthly)
    txn.valid?
    assert_not_nil txn.start_date
    assert_equal 15, txn.start_date.day
  end

  test "start_date not overwritten if already set" do
    existing_date = Date.new(2025, 6, 10)
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 15, frequency: :monthly, start_date: existing_date)
    txn.valid?
    assert_equal existing_date, txn.start_date
  end

  test "start_date auto-set handles end-of-month due_day" do
    txn = RecurringTransaction.new(name: "Test", amount: 10, due_day: 31, frequency: :monthly)
    txn.valid?
    assert_not_nil txn.start_date
    # Should clamp to last day of current month if month has fewer than 31 days
    last_day = Date.new(Date.current.year, Date.current.month, -1).day
    assert_equal [31, last_day].min, txn.start_date.day
  end

  # --- next_due_date calculation with Schedulable ---

  test "next_due_date is recalculated on save using Schedulable" do
    txn = RecurringTransaction.create!(name: "Test", amount: 50, due_day: 10, frequency: :monthly, start_date: Date.new(2026, 1, 10))
    assert_not_nil txn.next_due_date
    # Should be the next monthly occurrence after yesterday
    expected = txn.next_occurrence_after(Date.current - 1.day)
    assert_equal expected, txn.next_due_date
  end
end
