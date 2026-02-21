# frozen_string_literal: true

require "test_helper"

class DebtPayoffFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "can view debt comparison" do
    get debts_path
    assert_response :success
  end

  test "can view debt with extra payment" do
    get debts_path(extra_payment: 500)
    assert_response :success
  end
end
