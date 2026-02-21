# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get dashboard" do
    get root_url
    assert_response :success
  end

  test "dashboard displays heading" do
    get root_url
    assert_response :success
    assert_match "Dashboard", response.body
  end

  test "dashboard shows left to budget" do
    get root_url
    assert_response :success
    assert_match "Left to Budget", response.body
  end

  test "dashboard shows debt-free date section" do
    get root_url
    assert_response :success
    assert_match "Debt-Free Date", response.body
  end

  test "dashboard shows monthly cash flow" do
    get root_url
    assert_response :success
    assert_match "Monthly Cash Flow", response.body
  end

  test "dashboard shows net worth" do
    get root_url
    assert_response :success
    assert_match "Net Worth", response.body
  end

  test "dashboard shows recent transactions" do
    get root_url
    assert_response :success
    assert_match "Recent Transactions", response.body
  end

  test "dashboard shows savings goals" do
    get root_url
    assert_response :success
    assert_match "Savings Goals", response.body
  end

  test "dashboard shows upcoming bills" do
    get root_url
    assert_response :success
    assert_match "Upcoming Bills", response.body
  end

  test "dashboard requires authentication" do
    delete session_url
    get root_url
    assert_response :redirect
  end
end
