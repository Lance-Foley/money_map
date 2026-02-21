require "test_helper"

class BudgetCategoryTest < ActiveSupport::TestCase
  test "valid budget category" do
    category = BudgetCategory.new(name: "Test Category", position: 99)
    assert category.valid?
  end

  test "requires name" do
    category = BudgetCategory.new(position: 1)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    existing = budget_categories(:giving)
    category = BudgetCategory.new(name: existing.name, position: 99)
    assert_not category.valid?
    assert_includes category.errors[:name], "has already been taken"
  end

  test "requires position" do
    category = BudgetCategory.new(name: "New Category")
    assert_not category.valid?
    assert_includes category.errors[:position], "can't be blank"
  end

  test "position must be integer" do
    category = BudgetCategory.new(name: "New Category", position: 1.5)
    assert_not category.valid?
    assert_includes category.errors[:position], "must be an integer"
  end

  test "ordered scope returns categories by position" do
    categories = BudgetCategory.ordered
    positions = categories.map(&:position)
    assert_equal positions, positions.sort
  end

  test "fixture data loaded correctly" do
    assert_equal "Giving", budget_categories(:giving).name
    assert_equal 1, budget_categories(:giving).position
  end
end
