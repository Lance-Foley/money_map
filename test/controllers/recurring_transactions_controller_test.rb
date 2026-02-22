# frozen_string_literal: true

require "test_helper"

class RecurringTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @transaction = recurring_transactions(:rent_bill)
  end

  test "should get index" do
    get recurring_transactions_url
    assert_response :success
  end

  test "should get new" do
    get new_recurring_transaction_url
    assert_response :success
  end

  test "should create recurring transaction with valid params" do
    assert_difference("RecurringTransaction.count") do
      post recurring_transactions_url, params: {
        recurring_transaction: {
          name: "Internet",
          amount: 79.99,
          due_day: 20,
          frequency: "monthly",
          direction: "expense"
        }
      }
    end
    assert_redirected_to recurring_transactions_path
  end

  test "should create recurring income transaction" do
    assert_difference("RecurringTransaction.count") do
      post recurring_transactions_url, params: {
        recurring_transaction: {
          name: "Side Gig",
          amount: 500.00,
          due_day: 1,
          frequency: "monthly",
          direction: "income"
        }
      }
    end
    assert_redirected_to recurring_transactions_path
    txn = RecurringTransaction.last
    assert txn.income?
  end

  test "should not create recurring transaction with invalid params" do
    post recurring_transactions_url, params: {
      recurring_transaction: { name: "", amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_recurring_transaction_url(@transaction)
    assert_response :success
  end

  test "should update recurring transaction" do
    patch recurring_transaction_url(@transaction), params: { recurring_transaction: { amount: 1600.00 } }
    assert_redirected_to recurring_transactions_path
    @transaction.reload
    assert_equal 1600.00, @transaction.amount.to_f
  end

  test "should not update recurring transaction with invalid params" do
    patch recurring_transaction_url(@transaction), params: { recurring_transaction: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy recurring transaction" do
    assert_difference("RecurringTransaction.count", -1) do
      delete recurring_transaction_url(@transaction)
    end
    assert_redirected_to recurring_transactions_path
  end

  test "should create recurring transaction with custom frequency" do
    assert_difference("RecurringTransaction.count") do
      post recurring_transactions_url, params: { recurring_transaction: {
        name: "Every 6 weeks", amount: 100, due_day: 1,
        frequency: "custom", start_date: Date.current,
        custom_interval_value: 6, custom_interval_unit: 1
      } }
    end
    assert_redirected_to recurring_transactions_url

    txn = RecurringTransaction.last
    assert_equal "custom", txn.frequency
    assert_equal 6, txn.custom_interval_value
    assert_equal 1, txn.custom_interval_unit
    assert_equal Date.current, txn.start_date
  end

  test "should create recurring transaction with start_date" do
    assert_difference("RecurringTransaction.count") do
      post recurring_transactions_url, params: { recurring_transaction: {
        name: "Weekly Gym", amount: 50, due_day: 1,
        frequency: "weekly", start_date: Date.new(2026, 3, 2)
      } }
    end
    assert_redirected_to recurring_transactions_url

    txn = RecurringTransaction.last
    assert_equal Date.new(2026, 3, 2), txn.start_date
  end

  test "should update recurring transaction with new frequency fields" do
    patch recurring_transaction_url(@transaction), params: { recurring_transaction: {
      frequency: "weekly",
      start_date: Date.new(2026, 3, 1)
    } }
    assert_redirected_to recurring_transactions_path
    @transaction.reload
    assert_equal "weekly", @transaction.frequency
    assert_equal Date.new(2026, 3, 1), @transaction.start_date
  end
end
