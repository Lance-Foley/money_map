# Action Plan & Flexible Frequencies Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a MoneyMax-style Action Plan with multi-month cash flow projection, and upgrade recurring bill/income frequencies to support custom intervals.

**Architecture:** Two new services (Schedulable concern, ActionPlanGenerator, CashFlowCalculator), database migrations to add flexible frequency columns and budget item dates, new controller/views for the action plan. All changes are additive — existing budget and transaction views continue to work unchanged.

**Tech Stack:** Rails 8, Minitest, Phlex views, RubyUI components, Chart.js, Stimulus

**Design Doc:** `docs/plans/2026-02-21-action-plan-and-frequencies-design.md`

**Skills to load per task type:**
- Models/migrations: `rails-ai:models`, `rails-ai:testing`
- Controllers/routes: `rails-ai:controllers`, `rails-ai:testing`
- Views/components: `rails-ai:views`, `rails-ai:hotwire`, `rails-ai:styling`
- Services: `rails-ai:models`, `rails-ai:testing`

---

## Phase 1: Flexible Frequencies (Foundation)

### Task 1: Add Schedulable Concern with Frequency Calculations

**Files:**
- Create: `app/models/concerns/schedulable.rb`
- Create: `test/models/concerns/schedulable_test.rb`

**Step 1: Write failing tests**

```ruby
# test/models/concerns/schedulable_test.rb
require "test_helper"

class SchedulableTestModel
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Schedulable

  attribute :frequency, :integer
  attribute :start_date, :date
  attribute :custom_interval_value, :integer
  attribute :custom_interval_unit, :integer
end

class SchedulableTest < ActiveSupport::TestCase
  test "weekly next_occurrence_after returns correct date" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 2, 16), result # Monday after Feb 10
  end

  test "biweekly next_occurrence_after returns correct date" do
    model = SchedulableTestModel.new(frequency: 1, start_date: Date.new(2026, 1, 5))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert result >= Date.new(2026, 2, 10)
    # Should be on a 14-day cycle from start_date
    days_diff = (result - Date.new(2026, 1, 5)).to_i
    assert_equal 0, days_diff % 14
  end

  test "semimonthly next_occurrence_after returns 1st and 15th" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 2))
    assert_equal Date.new(2026, 2, 15), result
  end

  test "monthly next_occurrence_after returns same day next month" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 20))
    result = model.next_occurrence_after(Date.new(2026, 2, 21))
    assert_equal Date.new(2026, 3, 20), result
  end

  test "quarterly next_occurrence_after returns every 3 months" do
    model = SchedulableTestModel.new(frequency: 4, start_date: Date.new(2026, 1, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 4, 15), result
  end

  test "semi_annual next_occurrence_after returns every 6 months" do
    model = SchedulableTestModel.new(frequency: 5, start_date: Date.new(2026, 1, 10))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 7, 10), result
  end

  test "annual next_occurrence_after returns same date next year" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2025, 6, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 6, 15), result
  end

  test "custom frequency calculates correctly" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 6,
      custom_interval_unit: 1 # weeks
    )
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert result >= Date.new(2026, 2, 1)
    days_diff = (result - Date.new(2026, 1, 1)).to_i
    assert_equal 0, days_diff % 42 # 6 weeks * 7 days
  end

  test "occurrences_in_range returns all dates within range" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5)) # weekly
    dates = model.occurrences_in_range(Date.new(2026, 2, 1), Date.new(2026, 2, 28))
    assert dates.length >= 4
    assert dates.all? { |d| d >= Date.new(2026, 2, 1) && d <= Date.new(2026, 2, 28) }
  end

  test "schedule_description for preset frequencies" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 15))
    assert_equal "Monthly on the 15th", model.schedule_description
  end

  test "schedule_description for custom frequency" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 3,
      custom_interval_unit: 2 # months
    )
    assert_match(/every 3 months/i, model.schedule_description)
  end
end
```

**Step 2: Run tests to verify they fail**

```bash
bin/rails test test/models/concerns/schedulable_test.rb
```

Expected: FAIL (Schedulable module doesn't exist)

**Step 3: Implement the Schedulable concern**

```ruby
# app/models/concerns/schedulable.rb
module Schedulable
  extend ActiveSupport::Concern

  FREQUENCY_MAP = {
    0 => :weekly,
    1 => :biweekly,
    2 => :semimonthly,
    3 => :monthly,
    4 => :quarterly,
    5 => :semi_annual,
    6 => :annual,
    7 => :custom
  }.freeze

  INTERVAL_UNITS = { 0 => :days, 1 => :weeks, 2 => :months, 3 => :years }.freeze

  def next_occurrence_after(date)
    case frequency_name
    when :weekly
      advance_by_days(date, 7)
    when :biweekly
      advance_by_days(date, 14)
    when :semimonthly
      next_semimonthly(date)
    when :monthly
      advance_by_months(date, 1)
    when :quarterly
      advance_by_months(date, 3)
    when :semi_annual
      advance_by_months(date, 6)
    when :annual
      advance_by_months(date, 12)
    when :custom
      advance_by_custom(date)
    end
  end

  def occurrences_in_range(range_start, range_end)
    dates = []
    current = next_occurrence_on_or_after(range_start)
    while current && current <= range_end
      dates << current
      current = next_occurrence_after(current)
    end
    dates
  end

  def schedule_description
    case frequency_name
    when :weekly then "Weekly on #{start_date.strftime('%A')}s"
    when :biweekly then "Every 2 weeks on #{start_date.strftime('%A')}s"
    when :semimonthly then "1st and 15th of each month"
    when :monthly then "Monthly on the #{start_date.day.ordinalize}"
    when :quarterly then "Quarterly on the #{start_date.day.ordinalize}"
    when :semi_annual then "Every 6 months on the #{start_date.day.ordinalize}"
    when :annual then "Annually on #{start_date.strftime('%B %d')}"
    when :custom
      unit = INTERVAL_UNITS[custom_interval_unit]
      "Every #{custom_interval_value} #{unit} starting #{start_date.strftime('%b %d, %Y')}"
    end
  end

  private

  def frequency_name
    FREQUENCY_MAP[frequency]
  end

  def next_occurrence_on_or_after(date)
    candidate = next_occurrence_after(date - 1.day)
    candidate && candidate >= date ? candidate : next_occurrence_after(date)
  end

  def advance_by_days(after_date, interval)
    return start_date if start_date > after_date
    days_since = (after_date - start_date).to_i
    cycles = (days_since / interval) + 1
    start_date + (cycles * interval).days
  end

  def advance_by_months(after_date, interval)
    candidate = start_date
    while candidate <= after_date
      candidate = candidate >> interval
    end
    candidate
  end

  def next_semimonthly(after_date)
    day1 = [start_date.day, 1].max
    day2 = [day1 + 14, 28].min

    candidates = []
    (-1..2).each do |month_offset|
      ref = after_date >> month_offset
      [day1, day2].each do |d|
        safe_day = [d, Date.new(ref.year, ref.month, -1).day].min
        candidates << Date.new(ref.year, ref.month, safe_day)
      end
    end

    candidates.sort.find { |d| d > after_date }
  end

  def advance_by_custom(after_date)
    unit = INTERVAL_UNITS[custom_interval_unit]
    candidate = start_date
    loop do
      return candidate if candidate > after_date
      case unit
      when :days then candidate += custom_interval_value.days
      when :weeks then candidate += (custom_interval_value * 7).days
      when :months then candidate = candidate >> custom_interval_value
      when :years then candidate = candidate >> (custom_interval_value * 12)
      end
      break candidate if candidate > after_date
    end
  end
end
```

**Step 4: Run tests to verify they pass**

```bash
bin/rails test test/models/concerns/schedulable_test.rb
```

Expected: All PASS

**Step 5: Commit**

```bash
git add app/models/concerns/schedulable.rb test/models/concerns/schedulable_test.rb
git commit -m "feat: add Schedulable concern with flexible frequency calculations"
```

---

### Task 2: Migrate RecurringBill to Use Schedulable

**Files:**
- Create: `db/migrate/TIMESTAMP_add_flexible_frequency_to_recurring_bills.rb`
- Modify: `app/models/recurring_bill.rb`
- Modify: `test/models/recurring_bill_test.rb`
- Modify: `test/fixtures/recurring_bills.yml`

**Step 1: Generate migration**

```bash
bin/rails generate migration AddFlexibleFrequencyToRecurringBills \
  start_date:date \
  custom_interval_value:integer \
  custom_interval_unit:integer
```

Edit migration to set defaults and migrate existing data:

```ruby
class AddFlexibleFrequencyToRecurringBills < ActiveRecord::Migration[8.0]
  def up
    add_column :recurring_bills, :start_date, :date
    add_column :recurring_bills, :custom_interval_value, :integer
    add_column :recurring_bills, :custom_interval_unit, :integer

    # Migrate existing frequency values:
    # old: monthly: 0, quarterly: 1, annual: 2
    # new: weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3, quarterly: 4, semi_annual: 5, annual: 6, custom: 7
    execute <<-SQL
      UPDATE recurring_bills SET frequency = CASE frequency
        WHEN 0 THEN 3
        WHEN 1 THEN 4
        WHEN 2 THEN 6
        ELSE frequency
      END
    SQL

    # Set start_date from due_day for existing records
    execute <<-SQL
      UPDATE recurring_bills
      SET start_date = date('2026-01-01', '+' || (due_day - 1) || ' days')
      WHERE start_date IS NULL
    SQL
  end

  def down
    # Reverse the frequency mapping
    execute <<-SQL
      UPDATE recurring_bills SET frequency = CASE frequency
        WHEN 3 THEN 0
        WHEN 4 THEN 1
        WHEN 6 THEN 2
        ELSE 0
      END
    SQL

    remove_column :recurring_bills, :start_date
    remove_column :recurring_bills, :custom_interval_value
    remove_column :recurring_bills, :custom_interval_unit
  end
end
```

Run: `bin/rails db:migrate`

**Step 2: Update RecurringBill model**

Replace the model with:

```ruby
# app/models/recurring_bill.rb
class RecurringBill < ApplicationRecord
  include Schedulable

  belongs_to :account, optional: true
  belongs_to :budget_category, optional: true

  enum :frequency, {
    weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3,
    quarterly: 4, semi_annual: 5, annual: 6, custom: 7
  }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_day, presence: true, inclusion: { in: 1..31 }
  validates :start_date, presence: true
  validates :custom_interval_value, presence: true, numericality: { greater_than: 0 }, if: :custom?
  validates :custom_interval_unit, presence: true, if: :custom?

  scope :active, -> { where(active: true) }
  scope :due_soon, ->(days = 7) {
    today = Date.current
    active.where("next_due_date <= ?", today + days.days).where("next_due_date >= ?", today)
  }

  before_validation :set_start_date_from_due_day, if: -> { start_date.blank? && due_day.present? }
  before_save :calculate_next_due_date

  def days_until_due
    return nil unless next_due_date
    (next_due_date - Date.current).to_i
  end

  def overdue?
    next_due_date.present? && next_due_date < Date.current
  end

  private

  def set_start_date_from_due_day
    today = Date.current
    day = [due_day, Date.new(today.year, today.month, -1).day].min
    self.start_date = Date.new(today.year, today.month, day)
  end

  def calculate_next_due_date
    return unless start_date.present?
    self.next_due_date = next_occurrence_after(Date.current - 1.day)
  end
end
```

**Step 3: Update fixtures**

```yaml
# test/fixtures/recurring_bills.yml
rent_bill:
  name: Monthly Rent
  amount: 1500.00
  account: chase_checking
  budget_category: housing
  due_day: 1
  frequency: 3
  start_date: "2026-01-01"
  auto_create_transaction: false
  reminder_days_before: 3
  active: true
  next_due_date: "2026-03-01"

electric_bill:
  name: Electric Bill
  amount: 150.00
  account: chase_checking
  budget_category: utilities
  due_day: 15
  frequency: 3
  start_date: "2026-01-15"
  auto_create_transaction: true
  reminder_days_before: 5
  active: true
  next_due_date: "2026-02-15"

insurance_annual:
  name: Car Insurance
  amount: 1200.00
  budget_category: insurance
  due_day: 10
  frequency: 6
  start_date: "2025-06-10"
  active: true
  next_due_date: "2026-06-10"

inactive_bill:
  name: Old Subscription
  amount: 9.99
  due_day: 20
  frequency: 3
  start_date: "2025-01-20"
  active: false
  next_due_date: "2026-01-20"
```

**Step 4: Update tests**

Add new tests for expanded frequencies and Schedulable integration:

```ruby
# Append to test/models/recurring_bill_test.rb

test "expanded enum values are correct" do
  assert_equal "weekly", RecurringBill.new(frequency: 0).frequency
  assert_equal "biweekly", RecurringBill.new(frequency: 1).frequency
  assert_equal "semimonthly", RecurringBill.new(frequency: 2).frequency
  assert_equal "monthly", RecurringBill.new(frequency: 3).frequency
  assert_equal "quarterly", RecurringBill.new(frequency: 4).frequency
  assert_equal "semi_annual", RecurringBill.new(frequency: 5).frequency
  assert_equal "annual", RecurringBill.new(frequency: 6).frequency
  assert_equal "custom", RecurringBill.new(frequency: 7).frequency
end

test "custom frequency requires interval fields" do
  bill = RecurringBill.new(name: "Test", amount: 10, due_day: 1, frequency: :custom, start_date: Date.current)
  assert_not bill.valid?
  assert_includes bill.errors[:custom_interval_value], "can't be blank"
end

test "custom frequency with interval is valid" do
  bill = RecurringBill.new(
    name: "Test", amount: 10, due_day: 1, frequency: :custom,
    start_date: Date.current, custom_interval_value: 6, custom_interval_unit: 1
  )
  assert bill.valid?
end

test "schedule_description returns human readable string" do
  bill = recurring_bills(:rent_bill)
  assert_match(/monthly/i, bill.schedule_description)
end

test "occurrences_in_range returns dates for a month" do
  bill = recurring_bills(:rent_bill)
  dates = bill.occurrences_in_range(Date.new(2026, 3, 1), Date.new(2026, 5, 31))
  assert dates.length >= 3
end

test "start_date auto-set from due_day if blank" do
  bill = RecurringBill.new(name: "Test", amount: 10, due_day: 15, frequency: :monthly)
  bill.valid?
  assert_not_nil bill.start_date
  assert_equal 15, bill.start_date.day
end
```

Remove the old enum test (line 100-104) that tests old values.

**Step 5: Run tests**

```bash
bin/rails test test/models/recurring_bill_test.rb
```

Expected: All pass

**Step 6: Run full test suite to check for regressions**

```bash
bin/rails test
```

Expected: All pass (fix any tests that reference old frequency values)

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: expand RecurringBill frequencies with Schedulable concern"
```

---

### Task 3: Migrate Income to Use Schedulable

**Files:**
- Create: `db/migrate/TIMESTAMP_add_flexible_frequency_to_incomes.rb`
- Modify: `app/models/income.rb`
- Modify: `test/models/income_test.rb`
- Modify: `test/fixtures/incomes.yml`

**Step 1: Generate migration**

```bash
bin/rails generate migration AddFlexibleFrequencyToIncomes \
  start_date:date \
  custom_interval_value:integer \
  custom_interval_unit:integer \
  auto_generated:boolean \
  recurring_source_id:integer
```

Edit migration:

```ruby
class AddFlexibleFrequencyToIncomes < ActiveRecord::Migration[8.0]
  def up
    add_column :incomes, :start_date, :date
    add_column :incomes, :custom_interval_value, :integer
    add_column :incomes, :custom_interval_unit, :integer
    add_column :incomes, :auto_generated, :boolean, default: false
    add_column :incomes, :recurring_source_id, :integer

    add_index :incomes, :recurring_source_id

    # Migrate existing frequency values:
    # old: one_time: 0, weekly: 1, biweekly: 2, semimonthly: 3, monthly: 4
    # new: weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3, quarterly: 4, semi_annual: 5, annual: 6, custom: 7
    # one_time (0) -> set recurring to false, frequency to monthly (3) as default
    execute <<-SQL
      UPDATE incomes SET
        recurring = 0,
        frequency = 3
      WHERE frequency = 0
    SQL

    # weekly 1 -> 0, biweekly 2 -> 1, semimonthly 3 -> 2, monthly 4 -> 3
    # Must do in reverse order to avoid collisions
    execute "UPDATE incomes SET frequency = 3 WHERE frequency = 4"
    execute "UPDATE incomes SET frequency = 2 WHERE frequency = 3 AND recurring = 1"
    execute "UPDATE incomes SET frequency = 1 WHERE frequency = 2 AND recurring = 1"
    execute "UPDATE incomes SET frequency = 0 WHERE frequency = 1 AND recurring = 1"

    # Set start_date from pay_date for existing records
    execute <<-SQL
      UPDATE incomes SET start_date = pay_date WHERE start_date IS NULL AND pay_date IS NOT NULL
    SQL
  end

  def down
    remove_index :incomes, :recurring_source_id
    remove_column :incomes, :start_date
    remove_column :incomes, :custom_interval_value
    remove_column :incomes, :custom_interval_unit
    remove_column :incomes, :auto_generated
    remove_column :incomes, :recurring_source_id
  end
end
```

Run: `bin/rails db:migrate`

**Step 2: Update Income model**

```ruby
# app/models/income.rb
class Income < ApplicationRecord
  include Schedulable

  belongs_to :budget_period

  enum :frequency, {
    weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3,
    quarterly: 4, semi_annual: 5, annual: 6, custom: 7
  }

  validates :source_name, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than: 0 }
  validates :custom_interval_value, presence: true, numericality: { greater_than: 0 }, if: :custom?
  validates :custom_interval_unit, presence: true, if: :custom?

  scope :recurring_sources, -> { where(recurring: true, auto_generated: false) }

  after_save :recalculate_period_income
  after_destroy :recalculate_period_income

  def received?
    received_amount.present? && received_amount > 0
  end

  private

  def recalculate_period_income
    budget_period.recalculate_totals!
  end
end
```

**Step 3: Update fixtures**

```yaml
# test/fixtures/incomes.yml
main_paycheck:
  budget_period: current_period
  source_name: Employer Inc
  expected_amount: 2500.00
  received_amount: 2500.00
  pay_date: "2026-02-14"
  start_date: "2026-01-02"
  recurring: true
  frequency: 1

second_paycheck:
  budget_period: current_period
  source_name: Employer Inc
  expected_amount: 2500.00
  received_amount: 2500.00
  pay_date: "2026-02-28"
  start_date: "2026-01-16"
  recurring: true
  frequency: 1

freelance_income:
  budget_period: current_period
  source_name: Freelance Project
  expected_amount: 500.00
  pay_date: "2026-02-20"
  recurring: false
  frequency: 3

last_month_paycheck:
  budget_period: last_month
  source_name: Employer Inc
  expected_amount: 2500.00
  received_amount: 2500.00
  pay_date: "2026-01-14"
  start_date: "2026-01-02"
  recurring: true
  frequency: 1
```

**Step 4: Update tests**

Replace the old enum test in `test/models/income_test.rb`:

```ruby
test "expanded enum values are correct" do
  assert_equal "weekly", Income.new(frequency: 0).frequency
  assert_equal "biweekly", Income.new(frequency: 1).frequency
  assert_equal "semimonthly", Income.new(frequency: 2).frequency
  assert_equal "monthly", Income.new(frequency: 3).frequency
  assert_equal "quarterly", Income.new(frequency: 4).frequency
  assert_equal "semi_annual", Income.new(frequency: 5).frequency
  assert_equal "annual", Income.new(frequency: 6).frequency
  assert_equal "custom", Income.new(frequency: 7).frequency
end

test "custom frequency requires interval fields" do
  income = Income.new(
    budget_period: budget_periods(:current_period),
    source_name: "Test", expected_amount: 100,
    frequency: :custom, recurring: true
  )
  assert_not income.valid?
  assert_includes income.errors[:custom_interval_value], "can't be blank"
end

test "recurring_sources scope returns non-generated recurring income" do
  sources = Income.recurring_sources
  assert sources.all? { |i| i.recurring? && !i.auto_generated? }
end
```

**Step 5: Run tests**

```bash
bin/rails test
```

Expected: All pass

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: migrate Income to unified Schedulable frequency system"
```

---

### Task 4: Add expected_date and recurring_bill_id to BudgetItems

**Files:**
- Create: `db/migrate/TIMESTAMP_add_action_plan_fields_to_budget_items.rb`
- Modify: `app/models/budget_item.rb`
- Modify: `test/models/budget_item_test.rb`
- Modify: `test/fixtures/budget_items.yml`

**Step 1: Generate migration**

```bash
bin/rails generate migration AddActionPlanFieldsToBudgetItems \
  expected_date:date \
  recurring_bill_id:integer \
  auto_generated:boolean
```

Edit migration:

```ruby
class AddActionPlanFieldsToBudgetItems < ActiveRecord::Migration[8.0]
  def change
    add_column :budget_items, :expected_date, :date
    add_column :budget_items, :recurring_bill_id, :integer
    add_column :budget_items, :auto_generated, :boolean, default: false

    add_index :budget_items, :recurring_bill_id
    add_index :budget_items, :expected_date
    add_foreign_key :budget_items, :recurring_bills
  end
end
```

Run: `bin/rails db:migrate`

**Step 2: Update BudgetItem model**

Add to `app/models/budget_item.rb`:

```ruby
class BudgetItem < ApplicationRecord
  belongs_to :budget_period
  belongs_to :budget_category
  belongs_to :recurring_bill, optional: true
  has_many :transactions, dependent: :nullify
  has_many :transaction_splits, dependent: :destroy

  validates :name, presence: true
  validates :planned_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :by_category, ->(cat) { where(budget_category: cat) }
  scope :chronological, -> { order(:expected_date) }
  scope :for_recurring_bill, ->(bill) { where(recurring_bill: bill) }

  def remaining
    (planned_amount || 0) - (spent_amount || 0)
  end

  def over_budget?
    remaining.negative?
  end

  def percentage_spent
    return 0.0 if planned_amount.nil? || planned_amount.zero?
    ((spent_amount || 0).to_f / planned_amount * 100).round(1)
  end

  def sinking_fund?
    rollover?
  end

  def from_recurring?
    recurring_bill_id.present?
  end

  def recalculate_spent!
    total = transactions.sum(:amount) + transaction_splits.sum(:amount)
    update!(spent_amount: total)
    budget_period.recalculate_totals!
  end
end
```

**Step 3: Update fixtures to include expected_date**

```yaml
# test/fixtures/budget_items.yml
rent:
  budget_period: current_period
  budget_category: housing
  name: Rent
  planned_amount: 1500.00
  spent_amount: 1500.00
  expected_date: "2026-02-01"
  recurring_bill: rent_bill
  rollover: false

groceries:
  budget_period: current_period
  budget_category: food
  name: Groceries
  planned_amount: 600.00
  spent_amount: 450.00
  expected_date: "2026-02-07"
  rollover: false

electric:
  budget_period: current_period
  budget_category: utilities
  name: Electric
  planned_amount: 150.00
  spent_amount: 120.00
  expected_date: "2026-02-15"
  recurring_bill: electric_bill
  rollover: false

christmas_fund:
  budget_period: current_period
  budget_category: lifestyle
  name: Christmas Fund
  planned_amount: 100.00
  spent_amount: 0.00
  expected_date: "2026-02-01"
  rollover: true
  fund_goal: 1200.00
  fund_balance: 800.00

last_month_groceries:
  budget_period: last_month
  budget_category: food
  name: Groceries
  planned_amount: 600.00
  spent_amount: 580.00
  expected_date: "2026-01-07"
  rollover: false
```

**Step 4: Add tests**

```ruby
# Append to test/models/budget_item_test.rb

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

test "for_recurring_bill scope finds items from a bill" do
  items = BudgetItem.for_recurring_bill(recurring_bills(:rent_bill))
  assert items.all? { |i| i.recurring_bill_id == recurring_bills(:rent_bill).id }
end
```

**Step 5: Run tests**

```bash
bin/rails test
```

Expected: All pass

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add expected_date and recurring_bill_id to BudgetItems"
```

---

## Phase 2: Action Plan Services

### Task 5: ActionPlanGenerator Service

**Files:**
- Create: `app/services/action_plan_generator.rb`
- Create: `test/services/action_plan_generator_test.rb`

**Step 1: Write failing tests**

```ruby
# test/services/action_plan_generator_test.rb
require "test_helper"

class ActionPlanGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = ActionPlanGenerator.new(months_ahead: 3)
  end

  test "creates budget periods for future months" do
    # Clear future periods first
    BudgetPeriod.where("year > 2026 OR (year = 2026 AND month > 2)").destroy_all

    @generator.generate!

    # Should have periods for March, April, May 2026
    assert BudgetPeriod.find_by(year: 2026, month: 3)
    assert BudgetPeriod.find_by(year: 2026, month: 4)
    assert BudgetPeriod.find_by(year: 2026, month: 5)
  end

  test "creates budget items from recurring bills" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    rent_items = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill))
    assert_equal 1, rent_items.count
    assert_equal recurring_bills(:rent_bill).amount, rent_items.first.planned_amount
    assert rent_items.first.auto_generated?
  end

  test "creates income entries from recurring income" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    assert march.incomes.where(auto_generated: true).any?
  end

  test "does not duplicate existing items on re-run" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!
    count_before = BudgetItem.count

    @generator.generate!
    assert_equal count_before, BudgetItem.count
  end

  test "does not overwrite edited items" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    item.update!(planned_amount: 1600.00)

    @generator.generate!
    item.reload
    assert_equal 1600.00, item.planned_amount.to_f
  end

  test "sets expected_date based on recurring bill schedule" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    rent_item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    assert_not_nil rent_item.expected_date
    assert_equal 3, rent_item.expected_date.month
  end

  test "sets budget_category from recurring bill" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    rent_item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    assert_equal recurring_bills(:rent_bill).budget_category, rent_item.budget_category
  end

  test "skips inactive recurring bills" do
    BudgetPeriod.where("year = 2026 AND month >= 3").destroy_all
    @generator.generate!

    march = BudgetPeriod.find_by(year: 2026, month: 3)
    inactive_items = march.budget_items.where(recurring_bill: recurring_bills(:inactive_bill))
    assert_equal 0, inactive_items.count
  end
end
```

**Step 2: Run tests to verify they fail**

```bash
bin/rails test test/services/action_plan_generator_test.rb
```

Expected: FAIL (class doesn't exist)

**Step 3: Implement ActionPlanGenerator**

```ruby
# app/services/action_plan_generator.rb
class ActionPlanGenerator
  def initialize(months_ahead: 3, from_date: Date.current)
    @months_ahead = months_ahead
    @from_date = from_date
  end

  def generate!
    periods = ensure_periods_exist
    generate_bill_items(periods)
    generate_income_entries(periods)
    recalculate_totals(periods)
  end

  private

  def ensure_periods_exist
    (0...@months_ahead).map do |offset|
      target = @from_date >> offset
      BudgetPeriod.find_or_create_by!(year: target.year, month: target.month)
    end
  end

  def generate_bill_items(periods)
    RecurringBill.active.find_each do |bill|
      periods.each do |period|
        next if period.budget_items.exists?(recurring_bill: bill)

        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = bill.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          category = bill.budget_category || BudgetCategory.find_by(name: "Personal")
          period.budget_items.create!(
            name: bill.name,
            planned_amount: bill.amount,
            expected_date: occurrence_date,
            recurring_bill: bill,
            budget_category: category,
            auto_generated: true
          )
        end
      end
    end
  end

  def generate_income_entries(periods)
    Income.recurring_sources.find_each do |source|
      periods.each do |period|
        next if period.incomes.exists?(recurring_source_id: source.id)
        next unless source.start_date.present?

        range_start = Date.new(period.year, period.month, 1)
        range_end = range_start.end_of_month

        dates = source.occurrences_in_range(range_start, range_end)
        dates.each do |occurrence_date|
          period.incomes.create!(
            source_name: source.source_name,
            expected_amount: source.expected_amount,
            pay_date: occurrence_date,
            start_date: source.start_date,
            frequency: source.frequency,
            recurring: true,
            auto_generated: true,
            recurring_source_id: source.id
          )
        end
      end
    end
  end

  def recalculate_totals(periods)
    periods.each(&:recalculate_totals!)
  end
end
```

**Step 4: Run tests**

```bash
bin/rails test test/services/action_plan_generator_test.rb
```

Expected: All pass

**Step 5: Commit**

```bash
git add app/services/action_plan_generator.rb test/services/action_plan_generator_test.rb
git commit -m "feat: add ActionPlanGenerator service for multi-month projection"
```

---

### Task 6: CashFlowCalculator Service

**Files:**
- Create: `app/services/cash_flow_calculator.rb`
- Create: `test/services/cash_flow_calculator_test.rb`

**Step 1: Write failing tests**

```ruby
# test/services/cash_flow_calculator_test.rb
require "test_helper"

class CashFlowCalculatorTest < ActiveSupport::TestCase
  setup do
    @start_date = Date.new(2026, 2, 1)
    @end_date = Date.new(2026, 2, 28)
    @calculator = CashFlowCalculator.new(@start_date, @end_date)
  end

  test "returns timeline with chronological events" do
    result = @calculator.calculate
    assert result[:timeline].is_a?(Array)
    dates = result[:timeline].map { |e| e[:date] }
    assert_equal dates.sort, dates
  end

  test "income events have positive amounts" do
    result = @calculator.calculate
    income_events = result[:timeline].select { |e| e[:type] == :income }
    assert income_events.all? { |e| e[:amount] > 0 }
  end

  test "expense events have negative amounts in balance calculation" do
    result = @calculator.calculate
    assert result[:starting_balance].is_a?(Numeric)
  end

  test "running_balance tracks cumulative effect" do
    result = @calculator.calculate
    next if result[:timeline].empty?
    first = result[:timeline].first
    assert first.key?(:running_balance)
  end

  test "flags negative balance dates" do
    result = @calculator.calculate
    assert result.key?(:negative_dates)
    assert result[:negative_dates].is_a?(Array)
  end

  test "monthly_summary contains totals per month" do
    calculator = CashFlowCalculator.new(Date.new(2026, 2, 1), Date.new(2026, 4, 30))
    result = calculator.calculate
    assert result[:monthly_summary].is_a?(Array)
    result[:monthly_summary].each do |month|
      assert month.key?(:total_income)
      assert month.key?(:total_expenses)
      assert month.key?(:surplus)
    end
  end

  test "starting_balance uses current account balances" do
    result = @calculator.calculate
    expected = Account.active.where(account_type: [:checking, :savings]).sum(:balance).to_f
    assert_equal expected, result[:starting_balance]
  end
end
```

**Step 2: Run tests (fail), implement, run tests (pass)**

```ruby
# app/services/cash_flow_calculator.rb
class CashFlowCalculator
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def calculate
    starting_balance = Account.active.where(account_type: [:checking, :savings]).sum(:balance).to_f
    events = collect_events
    timeline = build_timeline(events, starting_balance)
    negative_dates = timeline.select { |e| e[:running_balance] < 0 }.map { |e| e[:date] }
    monthly_summary = build_monthly_summary(timeline)

    {
      starting_balance: starting_balance,
      timeline: timeline,
      negative_dates: negative_dates,
      monthly_summary: monthly_summary,
      chart_data: build_chart_data(timeline, starting_balance)
    }
  end

  private

  def collect_events
    events = []

    # Budget items (expenses) with expected dates in range
    BudgetItem.joins(:budget_period)
      .where("expected_date >= ? AND expected_date <= ?", @start_date, @end_date)
      .find_each do |item|
        events << {
          date: item.expected_date,
          name: item.name,
          amount: -(item.planned_amount || 0).to_f,
          type: :expense,
          source: item.from_recurring? ? :recurring : :manual,
          record_type: "BudgetItem",
          record_id: item.id
        }
      end

    # Incomes with pay dates in range
    Income.joins(:budget_period)
      .where("pay_date >= ? AND pay_date <= ?", @start_date, @end_date)
      .find_each do |income|
        events << {
          date: income.pay_date,
          name: income.source_name,
          amount: (income.expected_amount || 0).to_f,
          type: :income,
          source: income.recurring? ? :recurring : :manual,
          record_type: "Income",
          record_id: income.id
        }
      end

    events.sort_by { |e| [e[:date], e[:type] == :income ? 0 : 1] }
  end

  def build_timeline(events, starting_balance)
    running = starting_balance
    events.map do |event|
      running += event[:amount]
      event.merge(running_balance: running.round(2))
    end
  end

  def build_monthly_summary(timeline)
    timeline.group_by { |e| [e[:date].year, e[:date].month] }.map do |(year, month), events|
      income = events.select { |e| e[:type] == :income }.sum { |e| e[:amount] }
      expenses = events.select { |e| e[:type] == :expense }.sum { |e| e[:amount].abs }
      {
        year: year,
        month: month,
        display_name: Date.new(year, month, 1).strftime("%B %Y"),
        total_income: income.round(2),
        total_expenses: expenses.round(2),
        surplus: (income - expenses).round(2),
        ending_balance: events.last[:running_balance]
      }
    end
  end

  def build_chart_data(timeline, starting_balance)
    return { labels: [], data: [] } if timeline.empty?

    # One data point per day that has an event, plus start
    points = [{ label: @start_date.strftime("%b %d"), value: starting_balance }]
    timeline.each do |event|
      points << { label: event[:date].strftime("%b %d"), value: event[:running_balance] }
    end
    {
      labels: points.map { |p| p[:label] },
      data: points.map { |p| p[:value] }
    }
  end
end
```

**Step 3: Run tests**

```bash
bin/rails test test/services/cash_flow_calculator_test.rb
```

Expected: All pass

**Step 4: Commit**

```bash
git add app/services/cash_flow_calculator.rb test/services/cash_flow_calculator_test.rb
git commit -m "feat: add CashFlowCalculator service for running balance timeline"
```

---

## Phase 3: Action Plan Controller & Views

### Task 7: ActionPlanController

**Files:**
- Create: `app/controllers/action_plan_controller.rb`
- Create: `test/controllers/action_plan_controller_test.rb`
- Modify: `config/routes.rb`

**Step 1: Write controller tests**

```ruby
# test/controllers/action_plan_controller_test.rb
require "test_helper"

class ActionPlanControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "should get show" do
    get action_plan_url
    assert_response :success
  end

  test "show with custom months parameter" do
    get action_plan_url, params: { months: 6 }
    assert_response :success
  end

  test "generate creates future period items" do
    post generate_action_plan_url
    assert_redirected_to action_plan_url
  end

  test "create_item adds budget item to specified period" do
    period = budget_periods(:draft_period)
    post action_plan_items_url, params: {
      budget_item: {
        budget_period_id: period.id,
        budget_category_id: budget_categories(:food).id,
        name: "Special Dinner",
        planned_amount: 75.00,
        expected_date: Date.new(2026, 3, 15)
      }
    }
    assert_response :redirect
  end

  test "create_income adds income to specified period" do
    period = budget_periods(:draft_period)
    post action_plan_incomes_url, params: {
      income: {
        budget_period_id: period.id,
        source_name: "Bonus",
        expected_amount: 1000.00,
        pay_date: Date.new(2026, 3, 20)
      }
    }
    assert_response :redirect
  end

  test "update_item updates budget item amount" do
    item = budget_items(:rent)
    patch action_plan_item_url(item), params: {
      budget_item: { planned_amount: 1600.00 }
    }
    assert_response :redirect
    assert_equal 1600.00, item.reload.planned_amount.to_f
  end
end
```

**Step 2: Add routes**

Add to `config/routes.rb` before the root route:

```ruby
# Action Plan
get "action_plan", to: "action_plan#show", as: :action_plan
post "action_plan/generate", to: "action_plan#generate", as: :generate_action_plan
post "action_plan/items", to: "action_plan#create_item", as: :action_plan_items
patch "action_plan/items/:id", to: "action_plan#update_item", as: :action_plan_item
post "action_plan/incomes", to: "action_plan#create_income", as: :action_plan_incomes
patch "action_plan/incomes/:id", to: "action_plan#update_income", as: :action_plan_income
```

**Step 3: Implement controller**

```ruby
# app/controllers/action_plan_controller.rb
class ActionPlanController < ApplicationController
  def show
    months = (params[:months] || 3).to_i.clamp(1, 12)

    # Auto-generate future months
    ActionPlanGenerator.new(months_ahead: months).generate!

    start_date = Date.current.beginning_of_month
    end_date = (start_date >> months) - 1.day

    @cash_flow = CashFlowCalculator.new(start_date, end_date).calculate
    @months = months

    # Group items by period for the view
    @periods = BudgetPeriod.where(
      "year > ? OR (year = ? AND month >= ?)",
      start_date.year - 1, start_date.year, start_date.month
    ).where(
      "year < ? OR (year = ? AND month <= ?)",
      end_date.year + 1, end_date.year, end_date.month
    ).chronological.includes(budget_items: [:budget_category, :recurring_bill], incomes: [])

    @categories = BudgetCategory.ordered

    render Views::ActionPlan::ShowView.new(
      cash_flow: @cash_flow,
      periods: @periods,
      categories: @categories,
      months: @months
    )
  end

  def generate
    months = (params[:months] || 3).to_i.clamp(1, 12)
    ActionPlanGenerator.new(months_ahead: months).generate!
    redirect_to action_plan_path(months: months), notice: "Action plan regenerated."
  end

  def create_item
    @item = BudgetItem.new(item_params)
    if @item.save
      redirect_to action_plan_path, notice: "Item added."
    else
      redirect_to action_plan_path, alert: @item.errors.full_messages.join(", ")
    end
  end

  def update_item
    @item = BudgetItem.find(params[:id])
    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to action_plan_path, notice: "Item updated." }
      end
    else
      redirect_to action_plan_path, alert: @item.errors.full_messages.join(", ")
    end
  end

  def create_income
    @income = Income.new(income_params)
    if @income.save
      redirect_to action_plan_path, notice: "Income added."
    else
      redirect_to action_plan_path, alert: @income.errors.full_messages.join(", ")
    end
  end

  def update_income
    @income = Income.find(params[:id])
    if @income.update(income_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to action_plan_path, notice: "Income updated." }
      end
    else
      redirect_to action_plan_path, alert: @income.errors.full_messages.join(", ")
    end
  end

  private

  def item_params
    params.require(:budget_item).permit(
      :budget_period_id, :budget_category_id, :name,
      :planned_amount, :expected_date, :rollover, :fund_goal
    )
  end

  def income_params
    params.require(:income).permit(
      :budget_period_id, :source_name, :expected_amount,
      :pay_date, :recurring, :frequency
    )
  end
end
```

**Step 4: Run tests**

```bash
bin/rails test test/controllers/action_plan_controller_test.rb
```

Expected: All pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add ActionPlanController with CRUD for items and income"
```

---

### Task 8: Action Plan Phlex View

**Files:**
- Create: `app/views/action_plan/show_view.rb`

**Step 1: Build the view**

The view should have:
- Top: Chart.js line chart of running balance (green above zero, red below)
- Controls: months selector (3/6/12), regenerate button
- For each month: collapsible section with:
  - Income entries (green) with dates and amounts
  - Expense entries with dates and amounts
  - Each row: date | name | badge (recurring/one-off) | amount (editable) | running balance
  - Month subtotal row
  - "Add Item" and "Add Income" buttons
- Use RubyUI components: Card, Badge, Button, Dialog, Form, Input, Select, Accordion, Chart

Create the view at `app/views/action_plan/show_view.rb` using the Phlex component pattern matching existing views in the codebase. Reference `app/views/budgets/show_view.rb` for layout patterns.

The chart data comes from `@cash_flow[:chart_data]` — pass as JSON data attribute for the Stimulus chart_controller.

**Step 2: Add the "Action Plan" link to sidebar navigation**

In `app/components/money_map/sidebar_nav.rb`, add to NAV_ITEMS array after Budget (position index 2):

```ruby
{ label: "Action Plan", path: :action_plan_path, icon: :clipboard_list }
```

Add the `clipboard_list_icon` private method matching the SVG icon pattern used by other icons.

**Step 3: Boot server, verify the view renders**

```bash
bin/rails server -p 3000
```

Visit http://localhost:3000/action_plan and verify:
- Chart renders at top
- Month sections display with items
- Add item/income dialogs work
- Inline editing works

**Step 4: Run full test suite**

```bash
bin/rails test
```

Expected: All pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Action Plan view with cash flow chart and month sections"
```

---

### Task 9: Update Recurring Bills Form for New Frequencies

**Files:**
- Modify: `app/views/recurring_bills/form_view.rb`
- Modify: `app/controllers/recurring_bills_controller.rb`
- Modify: `test/controllers/recurring_bills_controller_test.rb`

**Step 1: Update strong params in controller**

Add `start_date`, `custom_interval_value`, `custom_interval_unit` to permitted params in `recurring_bills_controller.rb`.

**Step 2: Update the form view**

Add to the recurring bill form:
- Frequency select with all 8 options (weekly through custom)
- Start date date picker (always visible)
- Custom interval fields (visible only when "Custom" is selected — use Stimulus)
  - Interval value (number input)
  - Interval unit (select: days, weeks, months, years)
- Schedule preview text showing `schedule_description` output

**Step 3: Update controller tests**

Add test for creating a bill with custom frequency:

```ruby
test "should create recurring bill with custom frequency" do
  assert_difference("RecurringBill.count") do
    post recurring_bills_url, params: { recurring_bill: {
      name: "Every 6 weeks", amount: 100, due_day: 1,
      frequency: "custom", start_date: Date.current,
      custom_interval_value: 6, custom_interval_unit: 1
    }}
  end
  assert_redirected_to recurring_bills_url
end
```

**Step 4: Run tests, commit**

```bash
bin/rails test
git add -A
git commit -m "feat: update recurring bills form with flexible frequency options"
```

---

### Task 10: Update Income Form for New Frequencies

**Files:**
- Modify: `app/controllers/incomes_controller.rb`
- Modify: `app/views/budgets/show_view.rb` (income section)
- Modify: `test/controllers/incomes_controller_test.rb`

**Step 1: Update strong params**

Add `start_date`, `custom_interval_value`, `custom_interval_unit` to permitted params in `incomes_controller.rb`.

**Step 2: Update the income form in the budget view**

The income form (within budgets/show_view.rb or a separate component) needs:
- Frequency select with the new unified options
- Start date field
- Custom interval fields (conditional)

**Step 3: Update tests, run full suite, commit**

```bash
bin/rails test
git add -A
git commit -m "feat: update income form with flexible frequency options"
```

---

### Task 11: Update Seeds and Fixtures

**Files:**
- Modify: `db/seeds.rb`
- All fixture files that reference frequency values

**Step 1: Update seeds**

Update `db/seeds.rb` to:
- Use new frequency enum values (monthly: 3, etc.)
- Add `start_date` to all recurring bills
- Add `start_date` to all recurring incomes
- Add `expected_date` to budget items
- Add a custom-frequency bill example (e.g., "Every 6 weeks" pest control)

**Step 2: Update any remaining fixtures**

Scan all fixture files for old frequency values and update them to the new enum.

**Step 3: Reset and re-seed**

```bash
bin/rails db:seed:replant
```

Expected: Seeds complete without errors

**Step 4: Run full test suite**

```bash
bin/rails test
```

Expected: All pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: update seeds and fixtures for new frequency system and action plan"
```

---

### Task 12: Integration Test for Action Plan Flow

**Files:**
- Create: `test/integration/action_plan_flow_test.rb`

**Step 1: Write integration tests**

```ruby
# test/integration/action_plan_flow_test.rb
require "test_helper"

class ActionPlanFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "view action plan with generated future months" do
    get action_plan_url
    assert_response :success
  end

  test "add one-off expense to future month" do
    period = BudgetPeriod.find_or_create_by!(year: 2026, month: 4)
    post action_plan_items_url, params: {
      budget_item: {
        budget_period_id: period.id,
        budget_category_id: budget_categories(:food).id,
        name: "Birthday Dinner",
        planned_amount: 120.00,
        expected_date: Date.new(2026, 4, 15)
      }
    }
    assert_redirected_to action_plan_url
    assert BudgetItem.find_by(name: "Birthday Dinner")
  end

  test "edit generated item amount for one month only" do
    ActionPlanGenerator.new(months_ahead: 3).generate!
    march = BudgetPeriod.find_by(year: 2026, month: 3)
    item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    original_amount = item.planned_amount

    patch action_plan_item_url(item), params: {
      budget_item: { planned_amount: 1700.00 }
    }

    item.reload
    assert_equal 1700.00, item.planned_amount.to_f

    # April should still have original amount
    april = BudgetPeriod.find_by(year: 2026, month: 4)
    april_item = april.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    assert_equal original_amount.to_f, april_item.planned_amount.to_f
  end

  test "regenerate does not overwrite edited items" do
    ActionPlanGenerator.new(months_ahead: 3).generate!
    march = BudgetPeriod.find_by(year: 2026, month: 3)
    item = march.budget_items.where(recurring_bill: recurring_bills(:rent_bill)).first
    item.update!(planned_amount: 1700.00)

    post generate_action_plan_url
    item.reload
    assert_equal 1700.00, item.planned_amount.to_f
  end

  test "action plan shows running cash flow balance" do
    get action_plan_url
    assert_response :success
    # The response should contain chart data
  end
end
```

**Step 2: Run integration tests**

```bash
bin/rails test test/integration/action_plan_flow_test.rb
```

Expected: All pass

**Step 3: Run full test suite**

```bash
bin/rails test
```

Expected: All pass

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add integration tests for action plan flow"
```

---

## Build Order Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1: Frequencies | 1-4 | Schedulable concern, migrate RecurringBill + Income, BudgetItem fields |
| 2: Services | 5-6 | ActionPlanGenerator, CashFlowCalculator |
| 3: Controller/Views | 7-10 | ActionPlanController, Phlex views, form updates |
| 4: Polish | 11-12 | Seeds/fixtures, integration tests |

**Total: 12 tasks across 4 phases**

Each task is independently testable and committable. Phase 1 must complete before Phase 2 (services depend on new columns). Phase 3 depends on Phase 2 (controller uses services).
