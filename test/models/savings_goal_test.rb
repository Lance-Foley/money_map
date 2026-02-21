require "test_helper"

class SavingsGoalTest < ActiveSupport::TestCase
  test "valid savings goal" do
    goal = SavingsGoal.new(name: "Test Goal", target_amount: 5000.00)
    assert goal.valid?
  end

  test "requires name" do
    goal = SavingsGoal.new(target_amount: 5000.00)
    assert_not goal.valid?
    assert_includes goal.errors[:name], "can't be blank"
  end

  test "requires target_amount" do
    goal = SavingsGoal.new(name: "Test Goal")
    assert_not goal.valid?
    assert_includes goal.errors[:target_amount], "can't be blank"
  end

  test "target_amount must be greater than 0" do
    goal = SavingsGoal.new(name: "Test Goal", target_amount: 0)
    assert_not goal.valid?
    assert_includes goal.errors[:target_amount], "must be greater than 0"
  end

  test "current_amount defaults to zero" do
    goal = SavingsGoal.create!(name: "Test Goal", target_amount: 5000.00)
    assert_equal 0.0, goal.current_amount.to_f
  end

  test "progress_percentage calculates correctly" do
    goal = savings_goals(:emergency_fund)
    expected = (goal.current_amount.to_f / goal.target_amount * 100).round(1)
    assert_equal expected, goal.progress_percentage
  end

  test "progress_percentage caps at 100" do
    goal = SavingsGoal.new(name: "Over", target_amount: 100, current_amount: 200)
    assert_equal 100.0, goal.progress_percentage
  end

  test "progress_percentage returns 0 when target_amount is zero" do
    goal = SavingsGoal.new(name: "Zero", target_amount: 0)
    assert_equal 0.0, goal.progress_percentage
  end

  test "completed? returns true when current >= target" do
    assert savings_goals(:new_laptop).completed?
  end

  test "completed? returns false when current < target" do
    assert_not savings_goals(:emergency_fund).completed?
  end

  test "remaining calculates correctly" do
    goal = savings_goals(:emergency_fund)
    expected = goal.target_amount - goal.current_amount
    assert_equal expected, goal.remaining
  end

  test "remaining returns 0 when goal is completed" do
    goal = savings_goals(:new_laptop)
    assert_equal 0, goal.remaining
  end

  test "months_to_goal calculates correctly" do
    goal = savings_goals(:emergency_fund)
    remaining = goal.remaining
    monthly = 500.0
    expected = (remaining / monthly).ceil
    assert_equal expected, goal.months_to_goal(monthly)
  end

  test "months_to_goal returns nil for zero contribution" do
    goal = savings_goals(:emergency_fund)
    assert_nil goal.months_to_goal(0)
  end

  test "months_to_goal returns nil for nil contribution" do
    goal = savings_goals(:emergency_fund)
    assert_nil goal.months_to_goal(nil)
  end

  test "active scope returns incomplete goals" do
    active = SavingsGoal.active
    assert active.include?(savings_goals(:emergency_fund))
    assert_not active.include?(savings_goals(:new_laptop))
  end

  test "completed scope returns completed goals" do
    completed = SavingsGoal.completed
    assert completed.include?(savings_goals(:new_laptop))
    assert_not completed.include?(savings_goals(:emergency_fund))
  end

  test "by_priority scope orders by priority" do
    goals = SavingsGoal.by_priority
    priorities = goals.map(&:priority)
    assert_equal priorities, priorities.sort
  end

  test "enum values are correct" do
    assert_equal "emergency_fund", SavingsGoal.new(category: 0).category
    assert_equal "sinking_fund", SavingsGoal.new(category: 1).category
    assert_equal "general", SavingsGoal.new(category: 2).category
  end
end
