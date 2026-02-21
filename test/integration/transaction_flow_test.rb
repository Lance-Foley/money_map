# frozen_string_literal: true

require "test_helper"

class TransactionFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "can view transactions" do
    get transactions_path
    assert_response :success
  end

  test "can create a transaction" do
    account = accounts(:chase_checking)
    assert_difference("Transaction.count") do
      post transactions_path, params: {
        transaction: {
          account_id: account.id,
          date: Date.current,
          amount: 50.00,
          description: "Test purchase",
          transaction_type: "expense"
        }
      }
    end
    assert_redirected_to transactions_path
  end

  test "can edit a transaction" do
    transaction = transactions(:grocery_store)
    get edit_transaction_path(transaction)
    assert_response :success
  end

  test "can update a transaction" do
    transaction = transactions(:grocery_store)
    patch transaction_path(transaction), params: {
      transaction: { description: "Updated description" }
    }
    assert_redirected_to transactions_path
    transaction.reload
    assert_equal "Updated description", transaction.description
  end

  test "can filter uncategorized transactions" do
    get transactions_path(uncategorized: "true")
    assert_response :success
  end

  test "can search transactions" do
    get transactions_path(search: "Kroger")
    assert_response :success
  end
end
