# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @account = accounts(:chase_checking)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get show" do
    get account_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_url
    assert_response :success
  end

  test "should create account with valid params" do
    assert_difference("Account.count") do
      post accounts_url, params: { account: { name: "New Checking", account_type: "checking", balance: 1000.00 } }
    end
    assert_redirected_to accounts_path
  end

  test "should not create account with invalid params" do
    post accounts_url, params: { account: { name: "", account_type: "" } }
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "should update account with valid params" do
    patch account_url(@account), params: { account: { name: "Updated Name" } }
    assert_redirected_to account_path(@account)
    @account.reload
    assert_equal "Updated Name", @account.name
  end

  test "should not update account with invalid params" do
    patch account_url(@account), params: { account: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should deactivate account on destroy" do
    delete account_url(@account)
    assert_redirected_to accounts_path
    @account.reload
    assert_not @account.active
  end

  test "should redirect to login when not authenticated" do
    reset!
    get accounts_url
    assert_response :redirect
  end
end
