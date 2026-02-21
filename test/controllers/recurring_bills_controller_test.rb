# frozen_string_literal: true

require "test_helper"

class RecurringBillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @bill = recurring_bills(:rent_bill)
  end

  test "should get index" do
    get recurring_bills_url
    assert_response :success
  end

  test "should get new" do
    get new_recurring_bill_url
    assert_response :success
  end

  test "should create recurring bill with valid params" do
    assert_difference("RecurringBill.count") do
      post recurring_bills_url, params: {
        recurring_bill: {
          name: "Internet",
          amount: 79.99,
          due_day: 20,
          frequency: "monthly"
        }
      }
    end
    assert_redirected_to recurring_bills_path
  end

  test "should not create recurring bill with invalid params" do
    post recurring_bills_url, params: {
      recurring_bill: { name: "", amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_recurring_bill_url(@bill)
    assert_response :success
  end

  test "should update recurring bill" do
    patch recurring_bill_url(@bill), params: { recurring_bill: { amount: 1600.00 } }
    assert_redirected_to recurring_bills_path
    @bill.reload
    assert_equal 1600.00, @bill.amount.to_f
  end

  test "should not update recurring bill with invalid params" do
    patch recurring_bill_url(@bill), params: { recurring_bill: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy recurring bill" do
    assert_difference("RecurringBill.count", -1) do
      delete recurring_bill_url(@bill)
    end
    assert_redirected_to recurring_bills_path
  end
end
