# frozen_string_literal: true

require "test_helper"

class DebtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get index" do
    get debts_url
    assert_response :success
  end

  test "should get index with extra payment" do
    get debts_url(extra_payment: 500)
    assert_response :success
  end

  test "should get show for debt account" do
    account = accounts(:visa_card)
    get debt_url(account)
    assert_response :success
  end

  test "should get show for loan account" do
    account = accounts(:car_loan)
    get debt_url(account)
    assert_response :success
  end
end
