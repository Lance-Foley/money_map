# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get index" do
    get reports_url
    assert_response :success
  end

  test "should get index with custom period" do
    get reports_url(months: 6)
    assert_response :success
  end

  test "should get index with 3 month period" do
    get reports_url(months: 3)
    assert_response :success
  end

  test "should get index with 24 month period" do
    get reports_url(months: 24)
    assert_response :success
  end

  test "should display income vs expenses data" do
    get reports_url
    assert_response :success
    assert_select "h1", "Reports"
  end

  test "should require authentication" do
    delete session_url
    get reports_url
    assert_response :redirect
  end
end
