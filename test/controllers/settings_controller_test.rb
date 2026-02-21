# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get index" do
    get settings_url
    assert_response :success
  end

  test "should update profile with valid email" do
    patch update_profile_settings_url, params: { user: { email_address: "updated@example.com" } }
    assert_redirected_to settings_path
    users(:one).reload
    assert_equal "updated@example.com", users(:one).email_address
  end

  test "should not update profile with invalid email" do
    patch update_profile_settings_url, params: { user: { email_address: "" } }
    assert_response :unprocessable_entity
  end

  test "should create category" do
    assert_difference("BudgetCategory.count") do
      post create_category_settings_url, params: { budget_category: { name: "New Category", icon: "star", color: "#ff0000" } }
    end
    assert_redirected_to settings_path
  end

  test "should not create category without name" do
    assert_no_difference("BudgetCategory.count") do
      post create_category_settings_url, params: { budget_category: { name: "", icon: "star" } }
    end
    assert_redirected_to settings_path
  end

  test "should update category" do
    category = budget_categories(:food)
    patch update_category_settings_url(id: category.id), params: { budget_category: { name: "Groceries & Dining" } }
    assert_redirected_to settings_path
    category.reload
    assert_equal "Groceries & Dining", category.name
  end

  test "should destroy category" do
    category = budget_categories(:lifestyle)
    assert_difference("BudgetCategory.count", -1) do
      delete destroy_category_settings_url(id: category.id)
    end
    assert_redirected_to settings_path
  end

  test "should redirect to login when not authenticated" do
    reset!
    get settings_url
    assert_response :redirect
  end
end
