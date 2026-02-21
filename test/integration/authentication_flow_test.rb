# frozen_string_literal: true

require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get root_path
    assert_response :redirect
  end

  test "user can sign in and see dashboard" do
    sign_in_as(users(:one))
    get root_path
    assert_response :success
  end

  test "user can sign out" do
    sign_in_as(users(:one))
    delete session_path
    assert_response :redirect
    get root_path
    assert_response :redirect
  end

  test "invalid credentials show error" do
    post session_url, params: { email_address: "bad@example.com", password: "wrong" }
    assert_redirected_to new_session_path
  end
end
