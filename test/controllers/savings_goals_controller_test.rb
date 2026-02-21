# frozen_string_literal: true

require "test_helper"

class SavingsGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @goal = savings_goals(:emergency_fund)
  end

  test "should get index" do
    get savings_goals_url
    assert_response :success
  end

  test "should get new" do
    get new_savings_goal_url
    assert_response :success
  end

  test "should create savings goal with valid params" do
    assert_difference("SavingsGoal.count") do
      post savings_goals_url, params: {
        savings_goal: {
          name: "New Car Fund",
          target_amount: 5000.00,
          current_amount: 0,
          category: "general",
          priority: 5
        }
      }
    end
    assert_redirected_to savings_goals_path
  end

  test "should not create savings goal with invalid params" do
    post savings_goals_url, params: {
      savings_goal: { name: "", target_amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_savings_goal_url(@goal)
    assert_response :success
  end

  test "should update savings goal" do
    patch savings_goal_url(@goal), params: { savings_goal: { current_amount: 9000.00 } }
    assert_redirected_to savings_goals_path
    @goal.reload
    assert_equal 9000.00, @goal.current_amount.to_f
  end

  test "should not update savings goal with invalid params" do
    patch savings_goal_url(@goal), params: { savings_goal: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy savings goal" do
    assert_difference("SavingsGoal.count", -1) do
      delete savings_goal_url(@goal)
    end
    assert_redirected_to savings_goals_path
  end
end
