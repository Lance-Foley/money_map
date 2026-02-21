# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @transaction = transactions(:grocery_store)
    @account = accounts(:chase_checking)
  end

  test "should get index" do
    get transactions_url
    assert_response :success
  end

  test "should get index with account filter" do
    get transactions_url(account_id: @account.id)
    assert_response :success
  end

  test "should get index with uncategorized filter" do
    get transactions_url(uncategorized: "true")
    assert_response :success
  end

  test "should get index with search" do
    get transactions_url(search: "groceries")
    assert_response :success
  end

  test "should get index with date range" do
    get transactions_url(start_date: "2026-02-01", end_date: "2026-02-28")
    assert_response :success
  end

  test "should get new" do
    get new_transaction_url
    assert_response :success
  end

  test "should create transaction with valid params" do
    assert_difference("Transaction.count") do
      post transactions_url, params: {
        transaction: {
          account_id: @account.id,
          date: Date.current,
          amount: 50.00,
          description: "Test purchase",
          transaction_type: "expense"
        }
      }
    end
    assert_redirected_to transactions_path
  end

  test "should not create transaction with invalid params" do
    post transactions_url, params: {
      transaction: { amount: nil, date: nil }
    }
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_transaction_url(@transaction)
    assert_response :success
  end

  test "should update transaction" do
    patch transaction_url(@transaction), params: { transaction: { description: "Updated" } }
    assert_redirected_to transactions_path
    @transaction.reload
    assert_equal "Updated", @transaction.description
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_url(@transaction)
    end
    assert_redirected_to transactions_path
  end

  test "should bulk categorize transactions" do
    budget_item = budget_items(:groceries)
    uncategorized = transactions(:uncategorized_purchase)
    post bulk_categorize_transactions_url, params: {
      transaction_ids: [uncategorized.id],
      budget_item_id: budget_item.id
    }
    assert_redirected_to transactions_path
    uncategorized.reload
    assert_equal budget_item.id, uncategorized.budget_item_id
  end

  test "bulk categorize with missing params shows alert" do
    post bulk_categorize_transactions_url, params: {}
    assert_redirected_to transactions_path
  end
end
