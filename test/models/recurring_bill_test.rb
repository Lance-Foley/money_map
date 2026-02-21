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
    assert_equal 25, bill.next_due_date.day
  end

  test "enum values are correct" do
    assert_equal "monthly", RecurringBill.new(frequency: 0).frequency
    assert_equal "quarterly", RecurringBill.new(frequency: 1).frequency
    assert_equal "annual", RecurringBill.new(frequency: 2).frequency
  end
end
