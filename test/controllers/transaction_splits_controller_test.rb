# frozen_string_literal: true

require "test_helper"

class TransactionSplitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @transaction = transactions(:uncategorized_purchase)
    @budget_item = budget_items(:groceries)
  end

  test "should create split" do
    assert_difference("TransactionSplit.count") do
      post transaction_transaction_splits_url(@transaction), params: {
        transaction_split: { budget_item_id: @budget_item.id, amount: 10.00 }
      }
    end
    assert_redirected_to edit_transaction_path(@transaction)
  end

  test "should not create split without amount" do
    assert_no_difference("TransactionSplit.count") do
      post transaction_transaction_splits_url(@transaction), params: {
        transaction_split: { budget_item_id: @budget_item.id, amount: "" }
      }
    end
    assert_redirected_to edit_transaction_path(@transaction)
  end

  test "should destroy split" do
    split = transaction_splits(:groceries_split)
    transaction = split.transaction_record
    assert_difference("TransactionSplit.count", -1) do
      delete transaction_transaction_split_url(transaction, split)
    end
    assert_redirected_to edit_transaction_path(transaction)
  end
end
