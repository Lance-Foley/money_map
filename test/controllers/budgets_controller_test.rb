# frozen_string_literal: true

require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @period = budget_periods(:current_period)
  end

  test "should get show with defaults (current month)" do
    get budget_url
    assert_response :success
  end

  test "should get show with specific year/month" do
    get budget_url(year: 2026, month: 2)
    assert_response :success
  end

  test "should create period if it does not exist" do
    get budget_url(year: 2030, month: 6)
    assert_response :success
    assert BudgetPeriod.find_by(year: 2030, month: 6)
  end

  test "should copy previous month budget" do
    post copy_budget_url(year: 2026, month: 3)
    assert_redirected_to budget_path(year: 2026, month: 3)
    follow_redirect!
    assert_response :success
  end

  test "should handle no previous budget gracefully" do
    post copy_budget_url(year: 2020, month: 1)
    assert_redirected_to budget_path(year: 2020, month: 1)
  end

  test "should redirect to login when not authenticated" do
    reset!
    get budget_url
    assert_response :redirect
  end
end
