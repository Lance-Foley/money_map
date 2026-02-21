require "test_helper"

class RecurringBillTest < ActiveSupport::TestCase
  test "valid recurring bill" do
    bill = RecurringBill.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert bill.valid?
  end

  test "requires name" do
    bill = RecurringBill.new(amount: 15.99, due_day: 15)
    assert_not bill.valid?
    assert_includes bill.errors[:name], "can't be blank"
  end

  test "requires amount" do
    bill = RecurringBill.new(name: "Netflix", due_day: 15)
    assert_not bill.valid?
    assert_includes bill.errors[:amount], "can't be blank"
  end

  test "amount must be greater than 0" do
    bill = RecurringBill.new(name: "Netflix", amount: 0, due_day: 15)
    assert_not bill.valid?
    assert_includes bill.errors[:amount], "must be greater than 0"
  end

  test "requires due_day" do
    bill = RecurringBill.new(name: "Netflix", amount: 15.99)
    assert_not bill.valid?
    assert_includes bill.errors[:due_day], "can't be blank"
  end

  test "due_day must be between 1 and 31" do
    assert_not RecurringBill.new(name: "Test", amount: 10, due_day: 0).valid?
    assert_not RecurringBill.new(name: "Test", amount: 10, due_day: 32).valid?
    assert RecurringBill.new(name: "Test", amount: 10, due_day: 1).valid?
    assert RecurringBill.new(name: "Test", amount: 10, due_day: 31).valid?
  end

  test "account is optional" do
    bill = RecurringBill.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert bill.valid?
  end

  test "budget_category is optional" do
    bill = RecurringBill.new(name: "Netflix", amount: 15.99, due_day: 15)
    assert bill.valid?
  end

  test "active defaults to true" do
    bill = RecurringBill.create!(name: "Netflix", amount: 15.99, due_day: 15)
    assert bill.active?
  end

  test "auto_create_transaction defaults to false" do
    bill = RecurringBill.create!(name: "Netflix", amount: 15.99, due_day: 15)
    assert_not bill.auto_create_transaction?
  end

  test "active scope returns only active bills" do
    active_bills = RecurringBill.active
    assert active_bills.include?(recurring_bills(:rent_bill))
    assert_not active_bills.include?(recurring_bills(:inactive_bill))
  end

  test "overdue? returns true when next_due_date is in the past" do
    bill = recurring_bills(:inactive_bill)
    assert bill.overdue?
  end

  test "overdue? returns false when next_due_date is in the future" do
    bill = recurring_bills(:rent_bill)
    assert_not bill.overdue?
  end

  test "overdue? returns false when next_due_date is nil" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 15)
    bill.next_due_date = nil
    assert_not bill.overdue?
  end

  test "days_until_due calculates correctly" do
    bill = recurring_bills(:rent_bill)
    expected = (bill.next_due_date - Date.current).to_i
    assert_equal expected, bill.days_until_due
  end

  test "days_until_due returns nil when no next_due_date" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 15)
    bill.next_due_date = nil
    assert_nil bill.days_until_due
  end

  test "calculate_next_due_date sets date on create" do
    bill = RecurringBill.create!(name: "New Bill", amount: 99.99, due_day: 25)
    assert_not_nil bill.next_due_date
  end

  # --- Expanded frequency enum ---

  test "expanded enum values are correct" do
    assert_equal "weekly", RecurringBill.new(frequency: 0).frequency
    assert_equal "biweekly", RecurringBill.new(frequency: 1).frequency
    assert_equal "semimonthly", RecurringBill.new(frequency: 2).frequency
    assert_equal "monthly", RecurringBill.new(frequency: 3).frequency
    assert_equal "quarterly", RecurringBill.new(frequency: 4).frequency
    assert_equal "semi_annual", RecurringBill.new(frequency: 5).frequency
    assert_equal "annual", RecurringBill.new(frequency: 6).frequency
    assert_equal "custom", RecurringBill.new(frequency: 7).frequency
  end

  # --- Custom frequency validations ---

  test "custom frequency requires interval fields" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 1, frequency: :custom, start_date: Date.current)
    assert_not bill.valid?
    assert_includes bill.errors[:custom_interval_value], "can't be blank"
    assert_includes bill.errors[:custom_interval_unit], "can't be blank"
  end

  test "custom frequency with interval is valid" do
    bill = RecurringBill.new(
      name: "Test", amount: 10, due_day: 1, frequency: :custom,
      start_date: Date.current, custom_interval_value: 6, custom_interval_unit: 1
    )
    assert bill.valid?
  end

  test "custom_interval_value must be greater than 0" do
    bill = RecurringBill.new(
      name: "Test", amount: 10, due_day: 1, frequency: :custom,
      start_date: Date.current, custom_interval_value: 0, custom_interval_unit: 1
    )
    assert_not bill.valid?
    assert_includes bill.errors[:custom_interval_value], "must be greater than 0"
  end

  test "non-custom frequency does not require interval fields" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 1, frequency: :monthly)
    assert bill.valid?
  end

  # --- Schedulable integration: schedule_description ---

  test "schedule_description returns human readable string for monthly" do
    bill = recurring_bills(:rent_bill)
    assert_equal "Monthly on the 1st", bill.schedule_description
  end

  test "schedule_description returns human readable string for annual" do
    bill = recurring_bills(:insurance_annual)
    assert_equal "Annually on June 10", bill.schedule_description
  end

  # --- Schedulable integration: occurrences_in_range ---

  test "occurrences_in_range returns dates for monthly bill" do
    bill = recurring_bills(:rent_bill)
    dates = bill.occurrences_in_range(Date.new(2026, 3, 1), Date.new(2026, 5, 31))
    assert_equal 3, dates.length
    assert_equal [Date.new(2026, 3, 1), Date.new(2026, 4, 1), Date.new(2026, 5, 1)], dates
  end

  test "occurrences_in_range returns dates for annual bill" do
    bill = recurring_bills(:insurance_annual)
    dates = bill.occurrences_in_range(Date.new(2026, 1, 1), Date.new(2026, 12, 31))
    assert_equal 1, dates.length
    assert_equal Date.new(2026, 6, 10), dates.first
  end

  # --- start_date auto-set from due_day ---

  test "start_date auto-set from due_day if blank" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 15, frequency: :monthly)
    bill.valid?
    assert_not_nil bill.start_date
    assert_equal 15, bill.start_date.day
  end

  test "start_date not overwritten if already set" do
    existing_date = Date.new(2025, 6, 10)
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 15, frequency: :monthly, start_date: existing_date)
    bill.valid?
    assert_equal existing_date, bill.start_date
  end

  test "start_date auto-set handles end-of-month due_day" do
    bill = RecurringBill.new(name: "Test", amount: 10, due_day: 31, frequency: :monthly)
    bill.valid?
    assert_not_nil bill.start_date
    # Should clamp to last day of current month if month has fewer than 31 days
    last_day = Date.new(Date.current.year, Date.current.month, -1).day
    assert_equal [31, last_day].min, bill.start_date.day
  end

  # --- next_due_date calculation with Schedulable ---

  test "next_due_date is recalculated on save using Schedulable" do
    bill = RecurringBill.create!(name: "Test", amount: 50, due_day: 10, frequency: :monthly, start_date: Date.new(2026, 1, 10))
    assert_not_nil bill.next_due_date
    # Should be the next monthly occurrence after yesterday
    expected = bill.next_occurrence_after(Date.current - 1.day)
    assert_equal expected, bill.next_due_date
  end
end
