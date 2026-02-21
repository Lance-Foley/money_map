require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "valid transaction" do
    txn = Transaction.new(
      date: Date.current,
      amount: 50.00,
      transaction_type: :expense
    )
    assert txn.valid?
  end

  test "requires amount" do
    txn = Transaction.new(date: Date.current, transaction_type: :expense)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "can't be blank"
  end

  test "requires date" do
    txn = Transaction.new(amount: 50.00, transaction_type: :expense)
    assert_not txn.valid?
    assert_includes txn.errors[:date], "can't be blank"
  end

  test "requires transaction_type" do
    txn = Transaction.new(amount: 50.00, date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:transaction_type], "can't be blank"
  end

  test "account is optional" do
    txn = Transaction.new(date: Date.current, amount: 50.00, transaction_type: :expense)
    assert txn.valid?
  end

  test "budget_item is optional" do
    txn = Transaction.new(date: Date.current, amount: 50.00, transaction_type: :expense)
    assert txn.valid?
  end

  test "enum values are correct" do
    assert_equal "income", Transaction.new(transaction_type: 0).transaction_type
    assert_equal "expense", Transaction.new(transaction_type: 1).transaction_type
    assert_equal "transfer", Transaction.new(transaction_type: 2).transaction_type
  end

  test "by_date_range scope filters correctly" do
    start_date = Date.new(2026, 2, 1)
    end_date = Date.new(2026, 2, 28)
    results = Transaction.by_date_range(start_date, end_date)
    results.each do |txn|
      assert txn.date >= start_date
      assert txn.date <= end_date
    end
  end

  test "uncategorized scope returns transactions without budget_item" do
    results = Transaction.uncategorized
    results.each do |txn|
      assert_nil txn.budget_item_id
    end
    assert results.include?(transactions(:uncategorized_purchase))
  end

  test "chronological scope orders by date desc" do
    results = Transaction.chronological
    dates = results.map(&:date)
    assert_equal dates, dates.sort.reverse
  end

  test "imported scope returns imported transactions" do
    results = Transaction.imported
    results.each do |txn|
      assert txn.imported?
    end
    assert results.include?(transactions(:imported_transaction))
  end

  test "split? returns true when transaction has splits" do
    txn = transactions(:uncategorized_purchase)
    assert txn.split?
  end

  test "split? returns false when no splits" do
    txn = transactions(:grocery_store)
    assert_not txn.split?
  end
end
