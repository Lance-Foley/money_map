# MoneyMap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a personal budgeting and financial forecasting Rails 8 app combining Money Max Account's debt optimization with EveryDollar's zero-based budgeting.

**Architecture:** Rails 8 majestic monolith. Phlex views with RubyUI components. Hotwire for interactivity. SQLite database. Single admin user. SolidQueue for background CSV processing.

**Tech Stack:** Rails 8, Ruby 3.3+, SQLite, Phlex 2.4, RubyUI 1.1, Tailwind CSS 4, Hotwire (Turbo + Stimulus), Importmaps, SolidQueue, Chart.js, Minitest

**Design Doc:** `docs/plans/2026-02-21-moneymap-design.md`

**Skills to load per task type:**
- Models/migrations: `rails-ai:models`, `rails-ai:testing`
- Controllers/routes: `rails-ai:controllers`, `rails-ai:testing`
- Views/components: `rails-ai:views`, `rails-ai:hotwire`, `rails-ai:styling`
- Background jobs: `rails-ai:jobs`
- Security: `rails-ai:security`
- Project setup: `rails-ai:project-setup`

---

## Phase 1: Project Foundation

### Task 1: Create Rails 8 App

**Files:**
- Create: `money_map/` (entire Rails app directory)

**Step 1: Generate the Rails app**

```bash
cd /Users/lancefoley/code
rails new money_map --css=tailwind --database=sqlite3 --skip-jbuilder --skip-action-mailbox --skip-action-text
cd money_map
```

Expected: Fresh Rails 8 app with Tailwind CSS, SQLite, importmaps.

**Step 2: Verify app boots**

```bash
bin/rails server -p 3000 &
sleep 3
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
kill %1
```

Expected: HTTP 200

**Step 3: Initial commit**

```bash
git add -A
git commit -m "feat: initialize MoneyMap Rails 8 app"
```

---

### Task 2: Install Phlex + RubyUI

**Files:**
- Modify: `Gemfile`
- Create: `config/initializers/phlex.rb`
- Create: `config/initializers/ruby_ui.rb`
- Create: `app/components/base.rb`
- Create: `app/components/ruby_ui/base.rb`

**Step 1: Add gems to Gemfile**

Add to Gemfile:
```ruby
gem "phlex-rails", "~> 2.4"
gem "tailwind_merge"
gem "ruby_ui", github: "ruby-ui/ruby_ui", group: :development, require: false
```

Run:
```bash
bundle install
```

**Step 2: Run Phlex installer**

```bash
bin/rails generate phlex:install
```

**Step 3: Run RubyUI installer**

```bash
bin/rails generate ruby_ui:install
```

**Step 4: Generate core RubyUI components**

```bash
bin/rails g ruby_ui:component Accordion
bin/rails g ruby_ui:component Alert
bin/rails g ruby_ui:component Avatar
bin/rails g ruby_ui:component Badge
bin/rails g ruby_ui:component Breadcrumb
bin/rails g ruby_ui:component Button
bin/rails g ruby_ui:component Calendar
bin/rails g ruby_ui:component Card
bin/rails g ruby_ui:component Chart
bin/rails g ruby_ui:component Checkbox
bin/rails g ruby_ui:component Collapsible
bin/rails g ruby_ui:component Combobox
bin/rails g ruby_ui:component Dialog
bin/rails g ruby_ui:component DropdownMenu
bin/rails g ruby_ui:component Form
bin/rails g ruby_ui:component Input
bin/rails g ruby_ui:component Link
bin/rails g ruby_ui:component Pagination
bin/rails g ruby_ui:component Popover
bin/rails g ruby_ui:component Progress
bin/rails g ruby_ui:component Select
bin/rails g ruby_ui:component Separator
bin/rails g ruby_ui:component Sidebar
bin/rails g ruby_ui:component Switch
bin/rails g ruby_ui:component Table
bin/rails g ruby_ui:component Tabs
bin/rails g ruby_ui:component Textarea
bin/rails g ruby_ui:component ThemeToggle
bin/rails g ruby_ui:component Tooltip
bin/rails g ruby_ui:component Typography
```

**Step 5: Pin required JS libraries via importmap**

```bash
bin/importmap pin chart.js
bin/importmap pin tw-animate-css
```

**Step 6: Verify Phlex renders**

Create a simple test component and render it from a controller to confirm the stack works.

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: install Phlex, RubyUI, and Tailwind components"
```

---

### Task 3: Setup Authentication

**Files:**
- Create: `app/models/user.rb`
- Create: `app/controllers/sessions_controller.rb`
- Create: `db/migrate/*_create_users.rb`
- Create: `db/seeds.rb` (admin user)
- Create: `test/models/user_test.rb`

**Step 1: Run Rails 8 authentication generator**

```bash
bin/rails generate authentication
```

This creates User model, Session model, sessions controller, password resets, and all related views/routes.

**Step 2: Run migrations**

```bash
bin/rails db:migrate
```

**Step 3: Create admin seed**

In `db/seeds.rb`:
```ruby
User.find_or_create_by!(email_address: "admin@moneymap.local") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Admin user created: admin@moneymap.local / password123"
```

Run:
```bash
bin/rails db:seed
```

**Step 4: Write user model test**

```ruby
# test/models/user_test.rb
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin user exists after seed" do
    assert User.find_by(email_address: "admin@moneymap.local")
  end

  test "user requires email" do
    user = User.new(password: "password123")
    assert_not user.valid?
  end
end
```

**Step 5: Run tests**

```bash
bin/rails test
```

Expected: All pass.

**Step 6: Require authentication on all controllers**

In `app/controllers/application_controller.rb`:
```ruby
class ApplicationController < ActionController::Base
  include Authentication
end
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add authentication with Rails 8 generator and admin seed"
```

---

### Task 4: Application Layout with Sidebar Navigation

**Files:**
- Create: `app/views/layouts/application_layout.rb`
- Create: `app/views/components/sidebar_nav.rb`
- Create: `app/views/components/theme_toggle.rb`
- Create: `app/views/pages/dashboard_view.rb`
- Create: `app/controllers/pages_controller.rb`
- Modify: `config/routes.rb`
- Modify: `app/assets/stylesheets/application.tailwind.css`

**Step 1: Create the application Phlex layout**

Build `Views::Layouts::ApplicationLayout` as a Phlex component that wraps all pages:
- HTML head with meta tags, Tailwind, importmap includes
- Sidebar navigation (collapsible) using RubyUI Sidebar
- Main content area
- Theme toggle (RubyUI ThemeToggle component)
- Flash message display

Navigation links in sidebar:
1. Dashboard (home icon)
2. Budget (wallet icon)
3. Transactions (list icon)
4. Accounts (building icon)
5. Debt Payoff (target icon)
6. Savings & Goals (piggy-bank icon)
7. Recurring Bills (calendar icon)
8. Reports (chart icon)
9. Forecasting (trending-up icon)
10. Settings (gear icon)

**Step 2: Create PagesController with dashboard action**

```ruby
class PagesController < ApplicationController
  def dashboard
    render Views::Pages::DashboardView.new
  end
end
```

**Step 3: Set root route**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#dashboard"
end
```

**Step 4: Setup Tailwind CSS theme variables**

Configure CSS custom properties in `application.tailwind.css` for:
- Light theme colors (default)
- Dark theme colors (via `@media (prefers-color-scheme: dark)` and `.dark` class)
- Primary: indigo, Success: green, Warning: amber, Danger: red, Neutral: slate

**Step 5: Create a basic dashboard placeholder view**

```ruby
# app/views/pages/dashboard_view.rb
class Views::Pages::DashboardView < Views::Base
  def view_template
    div(class: "space-y-6") do
      h1(class: "text-2xl font-bold") { "Dashboard" }
      p { "Welcome to MoneyMap" }
    end
  end
end
```

**Step 6: Verify layout renders with sidebar**

Boot server and confirm:
- Login page appears (not authenticated)
- After login, sidebar navigation and dashboard render
- Theme toggle switches between dark/light
- Sidebar collapses/expands

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add application layout with sidebar navigation and theme toggle"
```

---

## Phase 2: Core Data Models

### Task 5: Account Model

**Files:**
- Create: `app/models/account.rb`
- Create: `db/migrate/*_create_accounts.rb`
- Create: `test/models/account_test.rb`
- Create: `test/fixtures/accounts.yml`

**Step 1: Write failing tests**

```ruby
# test/models/account_test.rb
require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(
      name: "Chase Checking",
      account_type: "checking",
      balance: 5000.00,
      active: true
    )
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(account_type: "checking")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires account_type" do
    account = Account.new(name: "Test")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "can't be blank"
  end

  test "account_type must be valid enum" do
    assert_raises(ArgumentError) do
      Account.new(account_type: "invalid")
    end
  end

  test "balance defaults to zero" do
    account = Account.create!(name: "Test", account_type: "checking")
    assert_equal 0.0, account.balance
  end

  test "scope active returns only active accounts" do
    assert Account.active.all?(&:active?)
  end

  test "scope by_type filters correctly" do
    checking = Account.by_type(:checking)
    checking.each { |a| assert_equal "checking", a.account_type }
  end

  test "debt? returns true for loans, mortgages, credit cards" do
    assert Account.new(account_type: "loan").debt?
    assert Account.new(account_type: "mortgage").debt?
    assert Account.new(account_type: "credit_card").debt?
    assert_not Account.new(account_type: "checking").debt?
  end

  test "asset? returns true for checking, savings, investment" do
    assert Account.new(account_type: "checking").asset?
    assert Account.new(account_type: "savings").asset?
    assert Account.new(account_type: "investment").asset?
    assert_not Account.new(account_type: "loan").asset?
  end
end
```

**Step 2: Run tests to verify they fail**

```bash
bin/rails test test/models/account_test.rb
```

Expected: FAIL (model doesn't exist)

**Step 3: Generate migration**

```bash
bin/rails generate model Account \
  name:string \
  account_type:integer \
  institution_name:string \
  balance:decimal{12,2} \
  interest_rate:decimal{5,4} \
  minimum_payment:decimal{10,2} \
  credit_limit:decimal{12,2} \
  original_balance:decimal{12,2} \
  active:boolean
```

Edit migration to add defaults:
```ruby
t.decimal :balance, precision: 12, scale: 2, default: 0.0
t.boolean :active, default: true
```

Run: `bin/rails db:migrate`

**Step 4: Implement Account model**

```ruby
# app/models/account.rb
class Account < ApplicationRecord
  enum :account_type, {
    checking: 0,
    savings: 1,
    credit_card: 2,
    loan: 3,
    mortgage: 4,
    investment: 5
  }

  validates :name, presence: true
  validates :account_type, presence: true
  validates :balance, numericality: true
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minimum_payment, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(account_type: type) }
  scope :debts, -> { where(account_type: [:credit_card, :loan, :mortgage]) }
  scope :assets, -> { where(account_type: [:checking, :savings, :investment]) }

  def debt?
    credit_card? || loan? || mortgage?
  end

  def asset?
    checking? || savings? || investment?
  end
end
```

**Step 5: Create fixtures**

```yaml
# test/fixtures/accounts.yml
chase_checking:
  name: Chase Checking
  account_type: 0
  institution_name: Chase
  balance: 5000.00
  active: true

ally_savings:
  name: Ally Savings
  account_type: 1
  institution_name: Ally Bank
  balance: 10000.00
  interest_rate: 0.045
  active: true

visa_card:
  name: Chase Visa
  account_type: 2
  institution_name: Chase
  balance: 3500.00
  interest_rate: 0.1999
  minimum_payment: 75.00
  credit_limit: 10000.00
  active: true

car_loan:
  name: Car Loan
  account_type: 3
  institution_name: Local Credit Union
  balance: 15000.00
  interest_rate: 0.0499
  minimum_payment: 350.00
  original_balance: 25000.00
  active: true

home_mortgage:
  name: Home Mortgage
  account_type: 4
  institution_name: Wells Fargo
  balance: 250000.00
  interest_rate: 0.0425
  minimum_payment: 1250.00
  original_balance: 300000.00
  active: true

inactive_account:
  name: Old Savings
  account_type: 1
  balance: 0.00
  active: false
```

**Step 6: Run tests**

```bash
bin/rails test test/models/account_test.rb
```

Expected: All pass.

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Account model with types, validations, and scopes"
```

---

### Task 6: BudgetCategory Model

**Files:**
- Create: `app/models/budget_category.rb`
- Create: `db/migrate/*_create_budget_categories.rb`
- Create: `test/models/budget_category_test.rb`
- Create: `test/fixtures/budget_categories.yml`
- Modify: `db/seeds.rb`

**Step 1: Write failing tests**

```ruby
# test/models/budget_category_test.rb
require "test_helper"

class BudgetCategoryTest < ActiveSupport::TestCase
  test "valid category" do
    cat = BudgetCategory.new(name: "Food", position: 1)
    assert cat.valid?
  end

  test "requires name" do
    cat = BudgetCategory.new(position: 1)
    assert_not cat.valid?
  end

  test "name must be unique" do
    BudgetCategory.create!(name: "Food", position: 1)
    dup = BudgetCategory.new(name: "Food", position: 2)
    assert_not dup.valid?
  end

  test "ordered by position" do
    positions = BudgetCategory.ordered.pluck(:position)
    assert_equal positions.sort, positions
  end
end
```

**Step 2: Run tests (fail), generate model, implement, seed defaults**

Model:
```ruby
class BudgetCategory < ApplicationRecord
  has_many :budget_items, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(:position) }
end
```

Seed default categories:
```ruby
categories = [
  { name: "Giving", position: 1, icon: "heart", color: "#ec4899" },
  { name: "Savings", position: 2, icon: "piggy-bank", color: "#10b981" },
  { name: "Housing", position: 3, icon: "home", color: "#6366f1" },
  { name: "Utilities", position: 4, icon: "zap", color: "#f59e0b" },
  { name: "Food", position: 5, icon: "utensils", color: "#ef4444" },
  { name: "Transportation", position: 6, icon: "car", color: "#3b82f6" },
  { name: "Insurance", position: 7, icon: "shield", color: "#8b5cf6" },
  { name: "Health", position: 8, icon: "activity", color: "#14b8a6" },
  { name: "Debt", position: 9, icon: "trending-down", color: "#f97316" },
  { name: "Personal", position: 10, icon: "user", color: "#64748b" },
  { name: "Lifestyle", position: 11, icon: "smile", color: "#a855f7" }
]

categories.each do |attrs|
  BudgetCategory.find_or_create_by!(name: attrs[:name]) do |cat|
    cat.assign_attributes(attrs)
  end
end
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add BudgetCategory model with default categories seed"
```

---

### Task 7: BudgetPeriod and BudgetItem Models

**Files:**
- Create: `app/models/budget_period.rb`
- Create: `app/models/budget_item.rb`
- Create: `db/migrate/*_create_budget_periods.rb`
- Create: `db/migrate/*_create_budget_items.rb`
- Create: `test/models/budget_period_test.rb`
- Create: `test/models/budget_item_test.rb`

**Step 1: Write failing tests for BudgetPeriod**

```ruby
# test/models/budget_period_test.rb
require "test_helper"

class BudgetPeriodTest < ActiveSupport::TestCase
  test "valid budget period" do
    bp = BudgetPeriod.new(year: 2026, month: 2)
    assert bp.valid?
  end

  test "month must be 1-12" do
    assert_not BudgetPeriod.new(year: 2026, month: 0).valid?
    assert_not BudgetPeriod.new(year: 2026, month: 13).valid?
  end

  test "unique year/month combination" do
    BudgetPeriod.create!(year: 2026, month: 2)
    dup = BudgetPeriod.new(year: 2026, month: 2)
    assert_not dup.valid?
  end

  test "status defaults to draft" do
    bp = BudgetPeriod.create!(year: 2026, month: 3)
    assert_equal "draft", bp.status
  end

  test "left_to_budget calculates correctly" do
    bp = budget_periods(:february_2026)
    expected = bp.total_income - bp.total_planned
    assert_equal expected, bp.left_to_budget
  end

  test "zero_based? returns true when left_to_budget is zero" do
    bp = BudgetPeriod.new(total_income: 5000, total_planned: 5000)
    assert bp.zero_based?
  end

  test "copy_from_previous creates items from prior month" do
    # Test that copying a budget period duplicates its items
    previous = budget_periods(:january_2026)
    current = BudgetPeriod.create!(year: 2026, month: 2)
    current.copy_from(previous)
    assert_equal previous.budget_items.count, current.budget_items.count
  end
end
```

**Step 2: Write failing tests for BudgetItem**

```ruby
# test/models/budget_item_test.rb
require "test_helper"

class BudgetItemTest < ActiveSupport::TestCase
  test "valid budget item" do
    item = BudgetItem.new(
      budget_period: budget_periods(:february_2026),
      budget_category: budget_categories(:food),
      name: "Groceries",
      planned_amount: 500.00
    )
    assert item.valid?
  end

  test "requires name" do
    item = BudgetItem.new(planned_amount: 500)
    assert_not item.valid?
  end

  test "remaining calculates correctly" do
    item = BudgetItem.new(planned_amount: 500, spent_amount: 350)
    assert_equal 150, item.remaining
  end

  test "over_budget? when spent exceeds planned" do
    item = BudgetItem.new(planned_amount: 500, spent_amount: 600)
    assert item.over_budget?
  end

  test "percentage_spent calculates correctly" do
    item = BudgetItem.new(planned_amount: 500, spent_amount: 250)
    assert_equal 50.0, item.percentage_spent
  end

  test "sinking fund rolls over balance" do
    item = BudgetItem.new(
      rollover: true,
      fund_goal: 1200,
      fund_balance: 400,
      planned_amount: 100,
      spent_amount: 0
    )
    assert item.sinking_fund?
    assert_equal 400, item.fund_balance
  end
end
```

**Step 3: Generate models, implement, run tests**

BudgetPeriod model:
```ruby
class BudgetPeriod < ApplicationRecord
  has_many :budget_items, dependent: :destroy
  has_many :incomes, dependent: :destroy

  enum :status, { draft: 0, active: 1, closed: 2 }

  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, uniqueness: { scope: :month }

  scope :chronological, -> { order(:year, :month) }
  scope :current, -> { where(year: Date.current.year, month: Date.current.month) }

  def left_to_budget
    (total_income || 0) - (total_planned || 0)
  end

  def zero_based?
    left_to_budget.zero?
  end

  def display_name
    Date.new(year, month, 1).strftime("%B %Y")
  end

  def copy_from(other_period)
    other_period.budget_items.each do |item|
      budget_items.create!(
        budget_category: item.budget_category,
        name: item.name,
        planned_amount: item.planned_amount,
        rollover: item.rollover,
        fund_goal: item.fund_goal,
        fund_balance: item.rollover? ? item.fund_balance + item.planned_amount - item.spent_amount : 0
      )
    end
  end

  def recalculate_totals!
    update!(
      total_income: incomes.sum(:received_amount),
      total_planned: budget_items.sum(:planned_amount),
      total_spent: budget_items.sum(:spent_amount)
    )
  end
end
```

BudgetItem model:
```ruby
class BudgetItem < ApplicationRecord
  belongs_to :budget_period
  belongs_to :budget_category
  has_many :transactions, dependent: :nullify
  has_many :transaction_splits, dependent: :destroy

  validates :name, presence: true
  validates :planned_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :by_category, ->(cat) { where(budget_category: cat) }

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

  def recalculate_spent!
    total = transactions.sum(:amount) + transaction_splits.sum(:amount)
    update!(spent_amount: total)
    budget_period.recalculate_totals!
  end
end
```

**Step 4: Create fixtures, run all tests, commit**

```bash
git add -A
git commit -m "feat: add BudgetPeriod and BudgetItem models with zero-based budgeting"
```

---

### Task 8: Transaction and TransactionSplit Models

**Files:**
- Create: `app/models/transaction.rb`
- Create: `app/models/transaction_split.rb`
- Create: `db/migrate/*_create_transactions.rb`
- Create: `db/migrate/*_create_transaction_splits.rb`
- Create: `test/models/transaction_test.rb`

**Step 1: Write failing tests**

Test Transaction:
- Valid with account, date, amount, description, transaction_type
- Requires amount, date, transaction_type
- Enum for transaction_type (income/expense/transfer)
- After save, recalculates budget_item.spent_amount
- Scope: by_date_range, uncategorized, income, expenses

Test TransactionSplit:
- Valid with transaction, budget_item, amount
- Split amounts must not exceed transaction amount
- After save, recalculates budget_item.spent_amount

**Step 2: Implement models**

Transaction model:
```ruby
class Transaction < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :budget_item, optional: true
  has_many :transaction_splits, dependent: :destroy

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }

  validates :amount, presence: true, numericality: true
  validates :date, presence: true
  validates :transaction_type, presence: true

  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :uncategorized, -> { where(budget_item_id: nil) }
  scope :chronological, -> { order(date: :desc) }
  scope :imported, -> { where(imported: true) }

  after_save :recalculate_budget_item
  after_destroy :recalculate_budget_item

  def split?
    transaction_splits.any?
  end

  private

  def recalculate_budget_item
    budget_item&.recalculate_spent!
  end
end
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Transaction and TransactionSplit models"
```

---

### Task 9: Income Model

**Files:**
- Create: `app/models/income.rb`
- Create: `db/migrate/*_create_incomes.rb`
- Create: `test/models/income_test.rb`

**Step 1: Write tests, implement model**

```ruby
class Income < ApplicationRecord
  belongs_to :budget_period

  enum :frequency, { one_time: 0, weekly: 1, biweekly: 2, semimonthly: 3, monthly: 4 }

  validates :source_name, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than: 0 }

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

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Income model for budget period income planning"
```

---

### Task 10: DebtPayment Model

**Files:**
- Create: `app/models/debt_payment.rb`
- Create: `db/migrate/*_create_debt_payments.rb`
- Create: `test/models/debt_payment_test.rb`

**Step 1: Write tests and implement**

```ruby
class DebtPayment < ApplicationRecord
  belongs_to :account
  belongs_to :budget_period, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true

  scope :for_account, ->(account) { where(account: account) }
  scope :chronological, -> { order(:payment_date) }

  after_save :update_account_balance

  private

  def update_account_balance
    # Reduce the debt account balance by principal portion
    if principal_portion.present? && principal_portion > 0
      account.update!(balance: account.balance - principal_portion)
    end
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add DebtPayment model for debt tracking"
```

---

### Task 11: SavingsGoal Model

**Files:**
- Create: `app/models/savings_goal.rb`
- Create: `db/migrate/*_create_savings_goals.rb`
- Create: `test/models/savings_goal_test.rb`

**Step 1: Write tests and implement**

```ruby
class SavingsGoal < ApplicationRecord
  enum :category, { emergency_fund: 0, sinking_fund: 1, general: 2 }

  validates :name, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where("current_amount < target_amount") }
  scope :completed, -> { where("current_amount >= target_amount") }
  scope :by_priority, -> { order(:priority) }

  def progress_percentage
    return 0.0 if target_amount.nil? || target_amount.zero?
    [(current_amount.to_f / target_amount * 100).round(1), 100.0].min
  end

  def completed?
    current_amount >= target_amount
  end

  def remaining
    [target_amount - (current_amount || 0), 0].max
  end

  def months_to_goal(monthly_contribution)
    return nil if monthly_contribution.nil? || monthly_contribution.zero?
    (remaining / monthly_contribution).ceil
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add SavingsGoal model with progress tracking"
```

---

### Task 12: RecurringBill Model

**Files:**
- Create: `app/models/recurring_bill.rb`
- Create: `db/migrate/*_create_recurring_bills.rb`
- Create: `test/models/recurring_bill_test.rb`

**Step 1: Write tests and implement**

```ruby
class RecurringBill < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :budget_category, optional: true

  enum :frequency, { monthly: 0, quarterly: 1, annual: 2 }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_day, presence: true, inclusion: { in: 1..31 }

  scope :active, -> { where(active: true) }
  scope :due_soon, ->(days = 7) {
    today = Date.current
    future = today + days.days
    active.where(due_day: today.day..future.day)
  }

  def next_due_date
    today = Date.current
    due = Date.new(today.year, today.month, [due_day, Date.new(today.year, today.month, -1).day].min)
    due < today ? due.next_month : due
  end

  def days_until_due
    (next_due_date - Date.current).to_i
  end

  def overdue?
    last_paid_date.nil? || last_paid_date < next_due_date.prev_month
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add RecurringBill model with due date tracking"
```

---

### Task 13: NetWorthSnapshot Model

**Files:**
- Create: `app/models/net_worth_snapshot.rb`
- Create: `db/migrate/*_create_net_worth_snapshots.rb`
- Create: `test/models/net_worth_snapshot_test.rb`

**Step 1: Write tests and implement**

```ruby
class NetWorthSnapshot < ApplicationRecord
  validates :recorded_at, presence: true, uniqueness: true
  validates :net_worth, presence: true

  scope :chronological, -> { order(:recorded_at) }
  scope :recent, ->(count = 12) { chronological.last(count) }

  def self.capture!
    assets = Account.active.assets.sum(:balance)
    liabilities = Account.active.debts.sum(:balance)

    breakdown = Account.active.map { |a|
      { id: a.id, name: a.name, type: a.account_type, balance: a.balance.to_f }
    }

    create!(
      recorded_at: Date.current,
      total_assets: assets,
      total_liabilities: liabilities,
      net_worth: assets - liabilities,
      breakdown: breakdown
    )
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add NetWorthSnapshot model with auto-capture"
```

---

### Task 14: CsvImport Model + Background Job

**Files:**
- Create: `app/models/csv_import.rb`
- Create: `app/jobs/process_csv_import_job.rb`
- Create: `db/migrate/*_create_csv_imports.rb`
- Create: `test/models/csv_import_test.rb`
- Create: `test/jobs/process_csv_import_job_test.rb`

**Step 1: Write tests and implement**

CsvImport model stores the uploaded file (via ActiveStorage), tracks processing status, and delegates to a SolidQueue background job.

```ruby
class CsvImport < ApplicationRecord
  belongs_to :account
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :account, presence: true

  after_create_commit :enqueue_processing

  def process!
    update!(status: :processing)

    imported = 0
    skipped = 0
    errors = []

    CSV.foreach(file.download, headers: true) do |row|
      begin
        account.transactions.create!(
          date: Date.parse(row[column_mapping["date"]]),
          amount: row[column_mapping["amount"]].to_f.abs,
          description: row[column_mapping["description"]],
          transaction_type: row[column_mapping["amount"]].to_f >= 0 ? :income : :expense,
          imported: true
        )
        imported += 1
      rescue => e
        skipped += 1
        errors << "Row #{imported + skipped}: #{e.message}"
      end
    end

    update!(
      status: :completed,
      records_imported: imported,
      records_skipped: skipped,
      error_log: errors.join("\n")
    )
  rescue => e
    update!(status: :failed, error_log: e.message)
  end

  private

  def enqueue_processing
    ProcessCsvImportJob.perform_later(self)
  end
end
```

ProcessCsvImportJob:
```ruby
class ProcessCsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv_import)
    csv_import.process!
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add CsvImport model with SolidQueue background processing"
```

---

### Task 15: Forecast Model

**Files:**
- Create: `app/models/forecast.rb`
- Create: `db/migrate/*_create_forecasts.rb`
- Create: `test/models/forecast_test.rb`

**Step 1: Write tests and implement**

```ruby
class Forecast < ApplicationRecord
  validates :name, presence: true
  validates :projection_months, presence: true, numericality: { in: 1..60 }

  # assumptions stored as JSON:
  # {
  #   monthly_income: 5000,
  #   monthly_expenses: 4000,
  #   extra_debt_payment: 500,
  #   income_growth_rate: 0.03,
  #   expense_growth_rate: 0.02
  # }

  def generate_projection!
    results = []
    income = assumptions["monthly_income"].to_f
    expenses = assumptions["monthly_expenses"].to_f
    debts = Account.active.debts.map { |d|
      { id: d.id, name: d.name, balance: d.balance.to_f,
        rate: d.interest_rate.to_f, min_payment: d.minimum_payment.to_f }
    }
    savings = Account.active.assets.sum(:balance).to_f

    projection_months.times do |month|
      surplus = income - expenses
      # Apply extra to debt
      debts.each do |debt|
        monthly_interest = debt[:balance] * (debt[:rate] / 12)
        payment = debt[:min_payment]
        debt[:balance] = [debt[:balance] + monthly_interest - payment, 0].max
      end

      savings += [surplus, 0].max
      total_debt = debts.sum { |d| d[:balance] }
      net_worth = savings - total_debt

      results << {
        month: month + 1,
        date: (Date.current + (month + 1).months).strftime("%Y-%m"),
        income: income.round(2),
        expenses: expenses.round(2),
        surplus: surplus.round(2),
        total_debt: total_debt.round(2),
        savings: savings.round(2),
        net_worth: net_worth.round(2)
      }

      # Apply growth rates
      income *= (1 + (assumptions["income_growth_rate"].to_f / 12))
      expenses *= (1 + (assumptions["expense_growth_rate"].to_f / 12))
    end

    update!(results: results)
  end

  def debt_free_month
    results&.find { |r| r["total_debt"].to_f <= 0 }&.dig("month")
  end
end
```

**Step 2: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Forecast model with financial projection engine"
```

---

## Phase 3: Debt Payoff Engine

### Task 16: DebtCalculator Service

**Files:**
- Create: `app/services/debt_calculator.rb`
- Create: `test/services/debt_calculator_test.rb`

This is the MMA-inspired heart of the app. Implements both snowball and avalanche strategies with comparison.

**Step 1: Write comprehensive tests**

```ruby
# test/services/debt_calculator_test.rb
require "test_helper"

class DebtCalculatorTest < ActiveSupport::TestCase
  setup do
    @debts = [
      { name: "Credit Card", balance: 3500, rate: 0.1999, min_payment: 75 },
      { name: "Car Loan", balance: 15000, rate: 0.0499, min_payment: 350 },
      { name: "Mortgage", balance: 250000, rate: 0.0425, min_payment: 1250 }
    ]
    @extra_payment = 500
  end

  test "snowball orders by balance ascending" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :snowball)
    result = calc.calculate
    assert_equal "Credit Card", result[:payoff_order].first[:name]
  end

  test "avalanche orders by interest rate descending" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert_equal "Credit Card", result[:payoff_order].first[:name]
  end

  test "avalanche saves more interest than snowball" do
    snowball = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :snowball).calculate
    avalanche = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche).calculate
    assert avalanche[:total_interest] <= snowball[:total_interest]
  end

  test "comparison returns both strategies" do
    result = DebtCalculator.compare(@debts, extra_payment: @extra_payment)
    assert result.key?(:snowball)
    assert result.key?(:avalanche)
    assert result.key?(:savings_difference)
  end

  test "calculates debt free date" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert result[:debt_free_date].is_a?(Date)
    assert result[:months_to_freedom] > 0
  end

  test "extra payment impact shows difference" do
    base = DebtCalculator.new(@debts, extra_payment: 0, strategy: :avalanche).calculate
    extra = DebtCalculator.new(@debts, extra_payment: 500, strategy: :avalanche).calculate
    assert extra[:months_to_freedom] < base[:months_to_freedom]
    assert extra[:total_interest] < base[:total_interest]
  end

  test "generates monthly payment schedule" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert result[:schedule].is_a?(Array)
    assert result[:schedule].first.key?(:month)
    assert result[:schedule].first.key?(:payments)
    assert result[:schedule].first.key?(:remaining_balance)
  end
end
```

**Step 2: Implement DebtCalculator**

```ruby
# app/services/debt_calculator.rb
class DebtCalculator
  def initialize(debts, extra_payment: 0, strategy: :avalanche)
    @debts = debts.map { |d| d.dup }
    @extra_payment = extra_payment
    @strategy = strategy
  end

  def calculate
    sorted = sort_debts(@debts.map(&:dup))
    schedule = []
    total_interest = 0
    month = 0

    loop do
      month += 1
      break if month > 600 # safety: 50 years max
      break if sorted.all? { |d| d[:balance] <= 0 }

      month_payments = []
      extra_remaining = @extra_payment

      sorted.each do |debt|
        next if debt[:balance] <= 0

        monthly_interest = debt[:balance] * (debt[:rate] / 12.0)
        total_interest += monthly_interest

        payment = debt[:min_payment]

        # First non-zero debt gets the extra payment
        if extra_remaining > 0 && debt == sorted.find { |d| d[:balance] > 0 }
          payment += extra_remaining
          extra_remaining = 0
        end

        payment = [payment, debt[:balance] + monthly_interest].min
        principal = payment - monthly_interest
        debt[:balance] = [debt[:balance] - principal, 0].max

        month_payments << {
          name: debt[:name],
          payment: payment.round(2),
          principal: principal.round(2),
          interest: monthly_interest.round(2),
          remaining: debt[:balance].round(2)
        }
      end

      schedule << {
        month: month,
        date: (Date.current + month.months).strftime("%Y-%m"),
        payments: month_payments,
        remaining_balance: sorted.sum { |d| d[:balance] }.round(2)
      }
    end

    {
      strategy: @strategy,
      payoff_order: sorted.map { |d| { name: d[:name], original_balance: d[:balance] } },
      months_to_freedom: month,
      debt_free_date: Date.current + month.months,
      total_interest: total_interest.round(2),
      total_paid: (sorted.sum { |d| @debts.find { |od| od[:name] == d[:name] }[:balance] } + total_interest).round(2),
      schedule: schedule
    }
  end

  def self.compare(debts, extra_payment: 0)
    snowball = new(debts, extra_payment: extra_payment, strategy: :snowball).calculate
    avalanche = new(debts, extra_payment: extra_payment, strategy: :avalanche).calculate

    {
      snowball: snowball,
      avalanche: avalanche,
      savings_difference: (snowball[:total_interest] - avalanche[:total_interest]).round(2),
      months_difference: snowball[:months_to_freedom] - avalanche[:months_to_freedom]
    }
  end

  private

  def sort_debts(debts)
    case @strategy
    when :snowball
      debts.sort_by { |d| d[:balance] }
    when :avalanche
      debts.sort_by { |d| -d[:rate] }
    end
  end
end
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add DebtCalculator service with snowball/avalanche strategies"
```

---

## Phase 4: Controllers & Views

### Task 17: Accounts CRUD

**Files:**
- Create: `app/controllers/accounts_controller.rb`
- Create: `app/views/accounts/index_view.rb`
- Create: `app/views/accounts/show_view.rb`
- Create: `app/views/accounts/form_view.rb`
- Create: `test/controllers/accounts_controller_test.rb`
- Modify: `config/routes.rb`

**Step 1: Write controller tests**

Test standard RESTful actions: index, show, new, create, edit, update, destroy.

**Step 2: Implement controller**

```ruby
class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]

  def index
    @accounts = Account.active.order(:account_type, :name)
    render Views::Accounts::IndexView.new(accounts: @accounts)
  end

  def show
    @transactions = @account.transactions.chronological.limit(50)
    render Views::Accounts::ShowView.new(account: @account, transactions: @transactions)
  end

  def new
    render Views::Accounts::FormView.new(account: Account.new)
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account created."
    else
      render Views::Accounts::FormView.new(account: @account), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Accounts::FormView.new(account: @account)
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account updated."
    else
      render Views::Accounts::FormView.new(account: @account), status: :unprocessable_entity
    end
  end

  def destroy
    @account.update!(active: false) # soft delete
    redirect_to accounts_path, notice: "Account deactivated."
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(
      :name, :account_type, :institution_name, :balance,
      :interest_rate, :minimum_payment, :credit_limit, :original_balance
    )
  end
end
```

**Step 3: Build Phlex views with RubyUI components**

Index view: Card grid layout showing each account with balance, type badge, and action dropdown.
Show view: Account detail with transactions table and balance history chart.
Form view: RubyUI Form with Input, Select, and Button components.

**Step 4: Add routes**

```ruby
resources :accounts
```

**Step 5: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Accounts CRUD with Phlex views and RubyUI components"
```

---

### Task 18: Budget Management (Monthly Budget View)

**Files:**
- Create: `app/controllers/budgets_controller.rb`
- Create: `app/controllers/budget_items_controller.rb`
- Create: `app/views/budgets/show_view.rb`
- Create: `app/views/budget_items/form_component.rb`
- Create: `test/controllers/budgets_controller_test.rb`
- Modify: `config/routes.rb`

This is the EveryDollar-inspired monthly budget view. The core screen of the app.

**Step 1: Write controller tests**

**Step 2: Implement BudgetsController**

```ruby
class BudgetsController < ApplicationController
  def show
    @period = find_or_create_period(params[:year], params[:month])
    @categories = BudgetCategory.ordered.includes(budget_items: :transactions)
    @items_by_category = @period.budget_items.group_by(&:budget_category_id)
    @incomes = @period.incomes

    render Views::Budgets::ShowView.new(
      period: @period,
      categories: @categories,
      items_by_category: @items_by_category,
      incomes: @incomes
    )
  end

  def copy_previous
    @period = find_or_create_period(params[:year], params[:month])
    previous = BudgetPeriod.where("year < ? OR (year = ? AND month < ?)",
      @period.year, @period.year, @period.month)
      .order(:year, :month).last

    if previous
      @period.copy_from(previous)
      redirect_to budget_path(year: @period.year, month: @period.month),
        notice: "Budget copied from #{previous.display_name}"
    else
      redirect_to budget_path(year: @period.year, month: @period.month),
        alert: "No previous budget to copy from"
    end
  end

  private

  def find_or_create_period(year, month)
    year ||= Date.current.year
    month ||= Date.current.month
    BudgetPeriod.find_or_create_by!(year: year.to_i, month: month.to_i)
  end
end
```

**Step 3: Implement BudgetItemsController (Turbo Frame CRUD)**

```ruby
class BudgetItemsController < ApplicationController
  before_action :set_budget_item, only: [:update, :destroy]

  def create
    @item = BudgetItem.new(budget_item_params)
    if @item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to budget_path(year: @item.budget_period.year, month: @item.budget_period.month) }
      end
    else
      render Views::BudgetItems::FormComponent.new(item: @item), status: :unprocessable_entity
    end
  end

  def update
    if @budget_item.update(budget_item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to budget_path(year: @budget_item.budget_period.year, month: @budget_item.budget_period.month) }
      end
    else
      render Views::BudgetItems::FormComponent.new(item: @budget_item), status: :unprocessable_entity
    end
  end

  def destroy
    period = @budget_item.budget_period
    @budget_item.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@budget_item) }
      format.html { redirect_to budget_path(year: period.year, month: period.month) }
    end
  end

  private

  def set_budget_item
    @budget_item = BudgetItem.find(params[:id])
  end

  def budget_item_params
    params.require(:budget_item).permit(
      :budget_period_id, :budget_category_id, :name,
      :planned_amount, :rollover, :fund_goal
    )
  end
end
```

**Step 4: Build the monthly budget Phlex view**

The ShowView should display:
- Month/year selector with prev/next navigation
- "Left to Budget" indicator at top (green when zero, red when not)
- Income section with editable income entries
- Budget categories as Accordions, each containing budget items
- Each item shows: name, planned, spent, remaining with inline editing
- "Add Item" button per category (opens Dialog with form)
- "Copy Previous Month" button
- Turbo Frames for inline editing without page reload

**Step 5: Add routes**

```ruby
get "budget/:year/:month", to: "budgets#show", as: :budget
post "budget/:year/:month/copy", to: "budgets#copy_previous", as: :copy_budget
resources :budget_items, only: [:create, :update, :destroy]
```

**Step 6: Run tests, commit**

```bash
git add -A
git commit -m "feat: add monthly budget view with categories, items, and Turbo inline editing"
```

---

### Task 19: Transactions Management

**Files:**
- Create: `app/controllers/transactions_controller.rb`
- Create: `app/views/transactions/index_view.rb`
- Create: `app/views/transactions/form_component.rb`
- Create: `test/controllers/transactions_controller_test.rb`
- Modify: `config/routes.rb`

**Step 1: Write controller tests**

**Step 2: Implement controller with search/filter**

```ruby
class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.chronological
    @transactions = @transactions.where(account_id: params[:account_id]) if params[:account_id].present?
    @transactions = @transactions.where(budget_item_id: params[:budget_item_id]) if params[:budget_item_id].present?
    @transactions = @transactions.uncategorized if params[:uncategorized] == "true"
    @transactions = @transactions.by_date_range(params[:start_date], params[:end_date]) if params[:start_date].present?
    @transactions = @transactions.where("description LIKE ?", "%#{params[:search]}%") if params[:search].present?
    @transactions = @transactions.page(params[:page]) # if using pagination

    render Views::Transactions::IndexView.new(
      transactions: @transactions,
      accounts: Account.active,
      budget_items: current_period_items
    )
  end

  def create
    @transaction = Transaction.new(transaction_params)
    if @transaction.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to transactions_path, notice: "Transaction added." }
      end
    else
      render Views::Transactions::FormComponent.new(transaction: @transaction), status: :unprocessable_entity
    end
  end

  def update
    @transaction = Transaction.find(params[:id])
    if @transaction.update(transaction_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to transactions_path }
      end
    else
      render Views::Transactions::FormComponent.new(transaction: @transaction), status: :unprocessable_entity
    end
  end

  def destroy
    Transaction.find(params[:id]).destroy
    redirect_to transactions_path, notice: "Transaction deleted."
  end

  # Bulk categorize uncategorized transactions
  def bulk_categorize
    Transaction.where(id: params[:transaction_ids]).update_all(budget_item_id: params[:budget_item_id])
    redirect_to transactions_path, notice: "Transactions categorized."
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :account_id, :budget_item_id, :date, :amount,
      :description, :merchant, :notes, :transaction_type
    )
  end

  def current_period_items
    period = BudgetPeriod.current.first
    period&.budget_items || []
  end
end
```

**Step 3: Build views with RubyUI Table, Dialog for quick-add, search/filter bar**

**Step 4: Add routes**

```ruby
resources :transactions do
  collection do
    post :bulk_categorize
  end
end
```

**Step 5: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Transactions with search, filters, quick-add, and bulk categorize"
```

---

### Task 20: CSV Import Interface

**Files:**
- Create: `app/controllers/csv_imports_controller.rb`
- Create: `app/views/csv_imports/new_view.rb`
- Create: `app/views/csv_imports/show_view.rb`
- Create: `test/controllers/csv_imports_controller_test.rb`

**Step 1: Implement CSV import flow**

1. User selects account and uploads CSV file
2. Preview screen shows first 5 rows with column mapping dropdowns
3. User maps columns: date, amount, description (minimum)
4. Submit triggers background job via SolidQueue
5. Progress shown via Turbo Stream updates
6. Results page shows imported/skipped/errors

**Step 2: Routes**

```ruby
resources :csv_imports, only: [:new, :create, :show]
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add CSV import with column mapping and background processing"
```

---

### Task 21: Debt Payoff Dashboard

**Files:**
- Create: `app/controllers/debts_controller.rb`
- Create: `app/views/debts/index_view.rb`
- Create: `app/views/debts/show_view.rb`
- Create: `app/views/debts/comparison_view.rb`
- Create: `test/controllers/debts_controller_test.rb`

**Step 1: Implement controller using DebtCalculator service**

```ruby
class DebtsController < ApplicationController
  def index
    @debt_accounts = Account.active.debts.order(:balance)
    @extra_payment = params[:extra_payment]&.to_f || 0

    debts_data = @debt_accounts.map { |a|
      { name: a.name, balance: a.balance.to_f, rate: a.interest_rate.to_f, min_payment: a.minimum_payment.to_f }
    }

    @comparison = DebtCalculator.compare(debts_data, extra_payment: @extra_payment) if debts_data.any?

    render Views::Debts::IndexView.new(
      accounts: @debt_accounts,
      comparison: @comparison,
      extra_payment: @extra_payment
    )
  end

  def show
    @account = Account.find(params[:id])
    @payments = @account.debt_payments.chronological

    render Views::Debts::ShowView.new(account: @account, payments: @payments)
  end
end
```

**Step 2: Build views**

Index view shows:
- All debt accounts in a Table with balances and rates
- Snowball vs Avalanche comparison Cards side-by-side
- Debt-free date for each strategy
- Total interest paid for each strategy
- Savings difference highlighted
- "Extra payment" input with Turbo Frame to recalculate on change
- Payment schedule timeline

Show view:
- Single debt detail with payment history
- Chart showing balance over time
- Projected payoff date

**Step 3: Routes**

```ruby
resources :debts, only: [:index, :show]
```

**Step 4: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Debt Payoff dashboard with snowball/avalanche comparison"
```

---

### Task 22: Savings & Goals

**Files:**
- Create: `app/controllers/savings_goals_controller.rb`
- Create: `app/views/savings_goals/index_view.rb`
- Create: `app/views/savings_goals/form_component.rb`
- Create: `test/controllers/savings_goals_controller_test.rb`

**Step 1: Standard CRUD with progress tracking views**

- Index shows all goals as Cards with Progress bars
- Separate sections: Emergency Fund, Sinking Funds, General Goals
- Each card shows: name, progress %, current/target amounts, months to goal
- Add/edit via Dialog

**Step 2: Routes**

```ruby
resources :savings_goals
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Savings Goals with progress tracking"
```

---

### Task 23: Recurring Bills

**Files:**
- Create: `app/controllers/recurring_bills_controller.rb`
- Create: `app/views/recurring_bills/index_view.rb`
- Create: `app/views/recurring_bills/form_component.rb`
- Create: `test/controllers/recurring_bills_controller_test.rb`

**Step 1: CRUD with calendar-style due date display**

- Index shows upcoming bills sorted by due date
- Calendar grid view option (month view)
- Color coding: green (paid), amber (upcoming), red (overdue)
- Quick "mark as paid" action

**Step 2: Routes**

```ruby
resources :recurring_bills
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Recurring Bills management with calendar view"
```

---

### Task 24: Income Management

**Files:**
- Create: `app/controllers/incomes_controller.rb`
- Create: `app/views/incomes/form_component.rb`
- Create: `test/controllers/incomes_controller_test.rb`

**Step 1: Inline CRUD within budget view via Turbo Frames**

- Add income source to budget period
- Mark income as received
- Track expected vs actual

**Step 2: Routes**

```ruby
resources :incomes, only: [:create, :update, :destroy]
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Income management within budget periods"
```

---

## Phase 5: Reports & Dashboard

### Task 25: Reports Controller & Chart Views

**Files:**
- Create: `app/controllers/reports_controller.rb`
- Create: `app/views/reports/index_view.rb`
- Create: `app/views/reports/components/` (chart components)
- Create: `test/controllers/reports_controller_test.rb`

**Step 1: Implement report data aggregation**

```ruby
class ReportsController < ApplicationController
  def index
    @period_range = params[:months]&.to_i || 12

    render Views::Reports::IndexView.new(
      income_vs_expenses: income_vs_expenses_data,
      spending_by_category: spending_by_category_data,
      net_worth_history: net_worth_data,
      debt_progress: debt_progress_data,
      budget_accuracy: budget_accuracy_data
    )
  end

  private

  def income_vs_expenses_data
    periods = BudgetPeriod.chronological.last(@period_range)
    periods.map { |p|
      { label: p.display_name, income: p.total_income, expenses: p.total_spent }
    }
  end

  def spending_by_category_data
    period = BudgetPeriod.current.first
    return [] unless period

    period.budget_items
      .joins(:budget_category)
      .group("budget_categories.name")
      .sum(:spent_amount)
      .map { |name, amount| { category: name, amount: amount } }
      .sort_by { |h| -h[:amount] }
  end

  def net_worth_data
    NetWorthSnapshot.recent(@period_range).map { |s|
      { date: s.recorded_at.strftime("%b %Y"), net_worth: s.net_worth,
        assets: s.total_assets, liabilities: s.total_liabilities }
    }
  end

  def debt_progress_data
    Account.active.debts.map { |a|
      { name: a.name, current: a.balance, original: a.original_balance,
        progress: a.original_balance.to_f > 0 ? ((a.original_balance - a.balance) / a.original_balance * 100).round(1) : 0 }
    }
  end

  def budget_accuracy_data
    periods = BudgetPeriod.chronological.last(@period_range)
    periods.map { |p|
      accuracy = p.total_planned.to_f > 0 ? (p.total_spent / p.total_planned * 100).round(1) : 0
      { period: p.display_name, planned: p.total_planned, actual: p.total_spent, accuracy: accuracy }
    }
  end
end
```

**Step 2: Build chart views using RubyUI Chart component**

Create Phlex components for each chart type:
- `IncomeVsExpensesChart` - grouped bar chart
- `SpendingByCategoryChart` - donut chart
- `NetWorthChart` - line chart with area fill
- `DebtProgressChart` - horizontal bar chart
- `BudgetAccuracyChart` - line chart
- `CashFlowChart` - waterfall/bar chart
- `MonthlyTrendsChart` - multi-line chart

Each chart component wraps the RubyUI `Chart` component with the appropriate data and options.

**Step 3: Tab-based layout for switching between report types**

Use RubyUI Tabs component to organize reports.

**Step 4: Routes**

```ruby
get "reports", to: "reports#index"
```

**Step 5: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Reports with 7 chart types using Chart.js"
```

---

### Task 26: Dashboard (Home Screen)

**Files:**
- Modify: `app/controllers/pages_controller.rb`
- Create: `app/views/pages/dashboard_view.rb` (full implementation)
- Create: `app/views/pages/components/` (dashboard widgets)

**Step 1: Implement dashboard data aggregation**

```ruby
class PagesController < ApplicationController
  def dashboard
    current_period = BudgetPeriod.current.first

    render Views::Pages::DashboardView.new(
      period: current_period,
      left_to_budget: current_period&.left_to_budget || 0,
      debt_free_dates: calculate_debt_free_dates,
      interest_savings: calculate_interest_savings,
      monthly_cash_flow: monthly_cash_flow,
      upcoming_bills: RecurringBill.active.due_soon(7),
      net_worth: latest_net_worth,
      recent_transactions: Transaction.chronological.limit(5)
    )
  end

  private

  def calculate_debt_free_dates
    debts = Account.active.debts.map { |a|
      { name: a.name, balance: a.balance.to_f, rate: a.interest_rate.to_f, min_payment: a.minimum_payment.to_f }
    }
    return nil if debts.empty?
    DebtCalculator.compare(debts)
  end

  def calculate_interest_savings
    debts = Account.active.debts
    return 0 if debts.empty?
    # Calculate vs minimum payments only
    debts.sum { |d|
      months_remaining = d.balance / d.minimum_payment rescue 0
      total_with_min = d.minimum_payment * months_remaining
      total_with_min - d.balance
    }
  end

  def monthly_cash_flow
    period = BudgetPeriod.current.first
    return { income: 0, spent: 0, remaining: 0 } unless period
    {
      income: period.total_income || 0,
      spent: period.total_spent || 0,
      remaining: (period.total_income || 0) - (period.total_spent || 0)
    }
  end

  def latest_net_worth
    snapshot = NetWorthSnapshot.chronological.last
    {
      current: snapshot&.net_worth || 0,
      previous: NetWorthSnapshot.chronological.second_to_last&.net_worth || 0
    }
  end
end
```

**Step 2: Build dashboard view with widget Cards**

Dashboard layout (2-column grid on desktop):
- **Top bar**: Left to Budget indicator (full width)
- **Row 1**: Debt-Free Date card | Interest Savings card
- **Row 2**: Monthly Cash Flow card | Net Worth card
- **Row 3**: Upcoming Bills list | Recent Transactions list
- **Quick Action**: Floating "Add Transaction" button (Dialog)

Each widget is a separate Phlex component using RubyUI Card.

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: build Dashboard with financial overview widgets"
```

---

### Task 27: Forecasting

**Files:**
- Create: `app/controllers/forecasts_controller.rb`
- Create: `app/views/forecasts/index_view.rb`
- Create: `app/views/forecasts/show_view.rb`
- Create: `app/views/forecasts/form_component.rb`
- Create: `test/controllers/forecasts_controller_test.rb`

**Step 1: Implement forecasting interface**

- Form to create a forecast with assumptions (monthly income, expenses, extra debt payment, growth rates)
- Pre-fill from current budget period data
- Generate projection button
- Results page shows:
  - Net worth trajectory chart (line)
  - Debt balance trajectory chart (line, declining)
  - Monthly surplus trend
  - Debt-free month highlight
  - Savings accumulation projection

**Step 2: Scenario comparison**

- Save multiple forecasts with different names
- Compare two forecasts side-by-side on a chart
- "What if" quick adjustments with Turbo Frames

**Step 3: Routes**

```ruby
resources :forecasts do
  member do
    post :generate
  end
end
```

**Step 4: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Forecasting with scenario modeling and projections"
```

---

## Phase 6: Settings & Polish

### Task 28: Settings Page

**Files:**
- Create: `app/controllers/settings_controller.rb`
- Create: `app/views/settings/index_view.rb`
- Create: `test/controllers/settings_controller_test.rb`

**Step 1: Build settings interface**

Sections (using RubyUI Tabs):
1. **Profile**: Update email, password
2. **Budget Categories**: Reorder, rename, add/remove categories (drag-and-drop with Stimulus)
3. **CSV Presets**: Save column mapping presets per bank
4. **Preferences**: Currency format, date format, default budget view

**Step 2: Routes**

```ruby
resource :settings, only: [:index, :update] do
  get :profile
  get :categories
  get :csv_presets
  get :preferences
end
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add Settings page with profile, categories, and preferences"
```

---

### Task 29: Login Page Styling

**Files:**
- Modify: Auth-related views (convert to Phlex if not already)
- Create: `app/views/sessions/new_view.rb`

**Step 1: Style login page**

Clean, centered login form with:
- App logo/name "MoneyMap" at top
- Email and password fields (RubyUI Input)
- Sign in button (RubyUI Button)
- Dark/light theme support
- No "sign up" link (single user app)

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: style login page with MoneyMap branding"
```

---

### Task 30: Transaction Splitting UI

**Files:**
- Create: `app/controllers/transaction_splits_controller.rb`
- Create: `app/views/transaction_splits/form_component.rb`
- Create: `test/controllers/transaction_splits_controller_test.rb`

**Step 1: Build split transaction interface**

When editing a transaction, user can:
- Click "Split" button
- Add multiple category + amount rows (Stimulus controller for dynamic rows)
- Amounts must sum to transaction total
- Save creates TransactionSplit records

**Step 2: Routes**

```ruby
resources :transactions do
  resources :transaction_splits, only: [:create, :destroy]
end
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add transaction splitting across budget categories"
```

---

### Task 31: Stimulus Controllers for Interactivity

**Files:**
- Create: `app/javascript/controllers/budget_controller.js` (inline editing)
- Create: `app/javascript/controllers/transaction_form_controller.js` (quick add)
- Create: `app/javascript/controllers/theme_controller.js` (dark/light toggle)
- Create: `app/javascript/controllers/chart_controller.js` (chart rendering)
- Create: `app/javascript/controllers/sidebar_controller.js` (collapse/expand)
- Create: `app/javascript/controllers/split_controller.js` (dynamic split rows)
- Create: `app/javascript/controllers/currency_controller.js` (format inputs)
- Create: `app/javascript/controllers/search_controller.js` (debounced search)

**Step 1: Implement each Stimulus controller**

Key behaviors:
- **budget_controller**: Inline edit planned amounts, auto-recalculate totals
- **transaction_form_controller**: Quick-add dialog, clear form after submit
- **theme_controller**: Toggle dark/light/system, persist preference in localStorage
- **chart_controller**: Initialize Chart.js instances from data attributes
- **sidebar_controller**: Toggle collapsed state, persist in localStorage
- **split_controller**: Add/remove split rows, validate totals
- **currency_controller**: Format currency inputs on blur
- **search_controller**: Debounce search input, submit Turbo Frame

**Step 2: Register all controllers**

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
// Each controller auto-registered via importmap stimulus-loading
```

**Step 3: Test interactivity manually, commit**

```bash
git add -A
git commit -m "feat: add Stimulus controllers for interactivity"
```

---

### Task 32: Net Worth Auto-Capture Job

**Files:**
- Create: `app/jobs/capture_net_worth_job.rb`
- Create: `test/jobs/capture_net_worth_job_test.rb`
- Modify: `config/recurring.yml` (SolidQueue recurring schedule)

**Step 1: Create recurring job**

```ruby
class CaptureNetWorthJob < ApplicationJob
  queue_as :default

  def perform
    NetWorthSnapshot.capture!
  end
end
```

**Step 2: Schedule monthly via SolidQueue**

```yaml
# config/recurring.yml
production:
  capture_net_worth:
    class: CaptureNetWorthJob
    schedule: "0 0 1 * *" # First day of each month at midnight
```

**Step 3: Run tests, commit**

```bash
git add -A
git commit -m "feat: add monthly net worth auto-capture via SolidQueue"
```

---

### Task 33: Bill Reminder Job

**Files:**
- Create: `app/jobs/bill_reminder_job.rb`
- Create: `test/jobs/bill_reminder_job_test.rb`

**Step 1: Create daily check job**

Checks for bills due within their `reminder_days_before` window and creates a flash notification (or stores in a Notification model if we want persistence).

For now, keep it simple: the dashboard query handles showing upcoming bills. This job can be added later for push notifications.

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add bill reminder background job"
```

---

### Task 34: Seed Comprehensive Demo Data

**Files:**
- Modify: `db/seeds.rb`

**Step 1: Create rich seed data**

```ruby
# db/seeds.rb - comprehensive demo data

# Admin user
admin = User.find_or_create_by!(email_address: "admin@moneymap.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

# Budget categories (already handled in Task 6)

# Accounts
checking = Account.find_or_create_by!(name: "Primary Checking") do |a|
  a.account_type = :checking
  a.institution_name = "Chase"
  a.balance = 4250.00
end

savings = Account.find_or_create_by!(name: "Emergency Savings") do |a|
  a.account_type = :savings
  a.institution_name = "Ally Bank"
  a.balance = 8500.00
  a.interest_rate = 0.045
end

credit_card = Account.find_or_create_by!(name: "Chase Sapphire") do |a|
  a.account_type = :credit_card
  a.institution_name = "Chase"
  a.balance = 2800.00
  a.interest_rate = 0.2199
  a.minimum_payment = 65.00
  a.credit_limit = 10000.00
end

car_loan = Account.find_or_create_by!(name: "Auto Loan") do |a|
  a.account_type = :loan
  a.institution_name = "Local CU"
  a.balance = 12500.00
  a.interest_rate = 0.0549
  a.minimum_payment = 325.00
  a.original_balance = 22000.00
end

mortgage = Account.find_or_create_by!(name: "Home Mortgage") do |a|
  a.account_type = :mortgage
  a.institution_name = "Wells Fargo"
  a.balance = 235000.00
  a.interest_rate = 0.0399
  a.minimum_payment = 1150.00
  a.original_balance = 275000.00
end

# Create budget periods with items for last 3 months
# Create sample transactions
# Create savings goals
# Create recurring bills
# Create net worth snapshots

puts "Seed data created successfully!"
puts "Login: admin@moneymap.local / password123"
```

Expand with realistic transactions, budget items, and historical data for 3 months.

**Step 2: Run seeds, verify**

```bash
bin/rails db:seed
bin/rails server
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add comprehensive seed data for demo"
```

---

### Task 35: Final Integration Testing & Polish

**Files:**
- Create: `test/integration/budget_flow_test.rb`
- Create: `test/integration/debt_payoff_flow_test.rb`
- Create: `test/system/` (system tests if time permits)

**Step 1: Write integration tests for critical flows**

1. Login → Dashboard → See financial overview
2. Create budget → Add items → Track spending
3. Add transaction → Categorize → See budget update
4. View debt comparison → Change extra payment → See recalculation
5. Create forecast → Generate projection → View charts
6. Import CSV → Map columns → See transactions

**Step 2: Run full test suite**

```bash
bin/rails test
```

**Step 3: Fix any failing tests or UI issues**

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: add integration tests and final polish"
```

---

## Build Order Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1: Foundation | 1-4 | Rails app, Phlex/RubyUI, auth, layout |
| 2: Models | 5-15 | All data models with tests |
| 3: Debt Engine | 16 | DebtCalculator service |
| 4: Controllers/Views | 17-24 | All CRUD screens |
| 5: Reports/Dashboard | 25-27 | Charts, dashboard, forecasting |
| 6: Polish | 28-35 | Settings, Stimulus, jobs, seeds, integration tests |

**Total: 35 tasks across 6 phases**

Each task is independently testable and committable. Later tasks depend on earlier ones but each produces working functionality.
