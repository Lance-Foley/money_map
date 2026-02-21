require "test_helper"

class BudgetItemTest < ActiveSupport::TestCase
  test "valid budget item" do
    item = BudgetItem.new(
      budget_period: budget_periods(:current_period),
      budget_category: budget_categories(:food),
      name: "Dining Out",
      planned_amount: 200.00
    )
    assert item.valid?
  end

  test "requires name" do
    item = BudgetItem.new(
      budget_period: budget_periods(:current_period),
      budget_category: budget_categories(:food),
      planned_amount: 200.00
    )
    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end

  test "planned_amount must be non-negative" do
    item = BudgetItem.new(
      budget_period: budget_periods(:current_period),
      budget_category: budget_categories(:food),
      name: "Test",
      planned_amount: -50.00
    )
    assert_not item.valid?
    assert_includes item.errors[:planned_amount], "must be greater than or equal to 0"
  end

  test "requires budget_period" do
    item = BudgetItem.new(
      budget_category: budget_categories(:food),
      name: "Test",
      planned_amount: 200.00
    )
    assert_not item.valid?
    assert_includes item.errors[:budget_period], "must exist"
  end

  test "requires budget_category" do
    item = BudgetItem.new(
      budget_period: budget_periods(:current_period),
      name: "Test",
      planned_amount: 200.00
    )
    assert_not item.valid?
    assert_includes item.errors[:budget_category], "must exist"
  end

  test "remaining calculates correctly" do
    item = budget_items(:groceries)
    expected = item.planned_amount - item.spent_amount
    assert_equal expected, item.remaining
  end

  test "over_budget? returns false when under budget" do
    assert_not budget_items(:groceries).over_budget?
  end

  test "over_budget? returns true when spent exceeds planned" do
    item = budget_items(:groceries)
    item.spent_amount = item.planned_amount + 100
    assert item.over_budget?
  end

  test "percentage_spent calculates correctly" do
    item = budget_items(:groceries)
    expected = ((item.spent_amount.to_f / item.planned_amount) * 100).round(1)
    assert_equal expected, item.percentage_spent
  end

  test "percentage_spent returns 0 when planned is zero" do
    item = BudgetItem.new(planned_amount: 0)
    assert_equal 0.0, item.percentage_spent
  end

  test "percentage_spent returns 0 when planned is nil" do
    item = BudgetItem.new(planned_amount: nil)
    assert_equal 0.0, item.percentage_spent
  end

  test "sinking_fund? returns true when rollover is true" do
    assert budget_items(:christmas_fund).sinking_fund?
  end

  test "sinking_fund? returns false when rollover is false" do
    assert_not budget_items(:groceries).sinking_fund?
  end

  test "by_category scope filters items" do
    food = budget_categories(:food)
    items = BudgetItem.by_category(food)
    items.each do |item|
      assert_equal food.id, item.budget_category_id
    end
  end

  test "from_recurring? returns true when linked to recurring bill" do
    assert budget_items(:rent).from_recurring?
  end

  test "from_recurring? returns false for manual items" do
    assert_not budget_items(:groceries).from_recurring?
  end

  test "chronological scope orders by expected_date" do
    items = BudgetItem.chronological
    dates = items.map(&:expected_date).compact
    assert_equal dates.sort, dates
  end

  test "for_recurring_bill scope finds items from a specific bill" do
    items = BudgetItem.for_recurring_bill(recurring_bills(:rent_bill))
    assert items.any?, "Expected at least one item for rent_bill"
    assert items.all? { |i| i.recurring_bill_id == recurring_bills(:rent_bill).id }
  end
end
