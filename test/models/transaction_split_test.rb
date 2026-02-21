require "test_helper"

class TransactionSplitTest < ActiveSupport::TestCase
  test "valid transaction split" do
    split = TransactionSplit.new(
      transaction_record: transactions(:grocery_store),
      budget_item: budget_items(:groceries),
      amount: 25.00
    )
    assert split.valid?
  end

  test "requires amount" do
    split = TransactionSplit.new(
      transaction_record: transactions(:grocery_store),
      budget_item: budget_items(:groceries)
    )
    assert_not split.valid?
    assert_includes split.errors[:amount], "can't be blank"
  end

  test "amount must be greater than 0" do
    split = TransactionSplit.new(
      transaction_record: transactions(:grocery_store),
      budget_item: budget_items(:groceries),
      amount: 0
    )
    assert_not split.valid?
    assert_includes split.errors[:amount], "must be greater than 0"
  end

  test "requires transaction_record" do
    split = TransactionSplit.new(
      budget_item: budget_items(:groceries),
      amount: 25.00
    )
    assert_not split.valid?
    assert_includes split.errors[:transaction_record], "must exist"
  end

  test "requires budget_item" do
    split = TransactionSplit.new(
      transaction_record: transactions(:grocery_store),
      amount: 25.00
    )
    assert_not split.valid?
    assert_includes split.errors[:budget_item], "must exist"
  end

  test "belongs to a transaction" do
    split = transaction_splits(:groceries_split)
    assert_equal transactions(:uncategorized_purchase), split.transaction_record
  end

  test "belongs to a budget item" do
    split = transaction_splits(:groceries_split)
    assert_equal budget_items(:groceries), split.budget_item
  end
end
