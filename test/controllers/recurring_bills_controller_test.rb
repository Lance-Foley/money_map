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

  test "should create recurring bill with custom frequency" do
    assert_difference("RecurringBill.count") do
      post recurring_bills_url, params: { recurring_bill: {
        name: "Every 6 weeks", amount: 100, due_day: 1,
        frequency: "custom", start_date: Date.current,
        custom_interval_value: 6, custom_interval_unit: 1
      } }
    end
    assert_redirected_to recurring_bills_url

    bill = RecurringBill.last
    assert_equal "custom", bill.frequency
    assert_equal 6, bill.custom_interval_value
    assert_equal 1, bill.custom_interval_unit
    assert_equal Date.current, bill.start_date
  end

  test "should create recurring bill with start_date" do
    assert_difference("RecurringBill.count") do
      post recurring_bills_url, params: { recurring_bill: {
        name: "Weekly Gym", amount: 50, due_day: 1,
        frequency: "weekly", start_date: Date.new(2026, 3, 2)
      } }
    end
    assert_redirected_to recurring_bills_url

    bill = RecurringBill.last
    assert_equal Date.new(2026, 3, 2), bill.start_date
  end

  test "should update recurring bill with new frequency fields" do
    patch recurring_bill_url(@bill), params: { recurring_bill: {
      frequency: "weekly",
      start_date: Date.new(2026, 3, 1)
    } }
    assert_redirected_to recurring_bills_path
    @bill.reload
    assert_equal "weekly", @bill.frequency
    assert_equal Date.new(2026, 3, 1), @bill.start_date
  end
end
