# MoneyMap - Design Document

**Date:** 2026-02-21
**Status:** Approved
**Author:** Lance Foley + Claude Architect

## Overview

MoneyMap is a personal budgeting and financial forecasting Rails 8 application that combines the best features of Money Max Account (debt optimization, cash flow analysis, interest savings) and EveryDollar (zero-based budgeting, sinking funds, transaction tracking).

## Tech Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Framework | Rails 8.0 | Latest stable, ships with everything needed |
| Ruby | 3.3+ | Current stable |
| Database | SQLite | Rails 8 default, perfect for single-user |
| Views | Phlex 2.4 + phlex-rails | Component-driven, pure Ruby views |
| UI Components | RubyUI 1.1 | shadcn-inspired, Phlex-native components |
| CSS | Tailwind CSS 4 | Via tailwindcss-rails gem |
| JS Delivery | Importmaps | No Node, no bundler |
| Interactivity | Hotwire (Turbo + Stimulus) | Rails 8 default |
| Background Jobs | SolidQueue | Rails 8 default (NO Redis/Sidekiq) |
| Caching | SolidCache | Rails 8 default |
| Auth | Rails 8 auth generator | Session-based, no Devise |
| Charts | Chart.js via RubyUI | Bar, line, pie, donut charts |
| CSV Parsing | Ruby stdlib CSV | No extra gems |
| Testing | Minitest | Rails default (NO RSpec) |

## User Scope

- Single admin user (personal finance dashboard)
- Default admin created via db/seeds.rb
- Session-based authentication via Rails 8 generator

## Data Model

### User
- email, password_digest, name, role (admin)

### Account
- name, account_type (checking/savings/credit_card/loan/mortgage/investment)
- institution_name, balance, interest_rate, minimum_payment
- credit_limit, original_balance, active

### BudgetPeriod
- year, month, status (draft/active/closed)
- total_income (cached), total_planned (cached), total_spent (cached)

### BudgetCategory
- name, position, icon, color
- Defaults: Giving, Savings, Housing, Utilities, Food, Transportation, Insurance, Health, Debt, Personal, Lifestyle

### BudgetItem
- budget_period_id, budget_category_id
- name, planned_amount, spent_amount (cached)
- rollover (boolean), fund_goal, fund_balance

### Transaction
- account_id, budget_item_id, date, amount
- description, merchant, notes
- transaction_type (income/expense/transfer)
- imported (boolean)

### TransactionSplit
- transaction_id, budget_item_id, amount

### Income
- budget_period_id, source_name, expected_amount, received_amount
- pay_date, recurring, frequency

### DebtAccount (STI or extension of Account)
- payoff_order_snowball, payoff_order_avalanche
- projected_payoff_date_snowball, projected_payoff_date_avalanche
- total_interest_saved

### DebtPayment
- debt_account_id, budget_period_id
- amount, payment_date, principal_portion, interest_portion

### SavingsGoal
- name, target_amount, current_amount, target_date
- category (emergency_fund/sinking_fund/general), priority

### RecurringBill
- name, amount, account_id, budget_category_id
- due_day, frequency (monthly/quarterly/annual)
- auto_create_transaction, reminder_days_before
- active, last_paid_date, next_due_date

### NetWorthSnapshot
- recorded_at, total_assets, total_liabilities, net_worth
- breakdown (jsonb)

### CsvImport
- file_name, status (pending/processing/completed/failed)
- account_id, records_imported, records_skipped, error_log

### Forecast
- name, assumptions (jsonb)
- projection_months, created_at
- results (jsonb - calculated projections)

## Feature Map

### 1. Dashboard
- Left to Budget indicator (zero-based check)
- Debt-free date projection (snowball & avalanche)
- Total interest savings vs minimum payments
- Monthly cash flow summary
- Quick-add transaction button
- Upcoming bills widget (next 7 days)
- Net worth with trend arrow

### 2. Budget (EveryDollar-inspired)
- Monthly budget view with categories and line items
- Planned vs Spent vs Remaining per line item
- Drag-and-drop transaction assignment
- Copy previous month
- Sinking fund tracking with rollover
- Income planning section

### 3. Transactions
- Transaction list with search and filters
- Manual entry form (quick-add dialog)
- CSV import with column mapping
- Split transaction across categories
- Bulk categorize uncategorized

### 4. Accounts
- Account list by type
- Account detail with transactions
- Balance history chart
- Add/edit/deactivate

### 5. Debt Payoff (MMA-inspired)
- Debt overview ranked by strategy
- Snowball vs Avalanche side-by-side comparison
- Debt-free date calculator with what-if
- Interest savings projection
- Payment schedule
- Extra payment impact calculator
- Payment history per debt

### 6. Savings & Goals
- Active goals with progress bars
- Emergency fund tracker
- Sinking funds overview
- Goal timeline projections

### 7. Reports & Insights
- Income vs Expenses (bar chart, monthly)
- Spending by category (pie/donut)
- Monthly trends over time
- Net worth over time (line chart)
- Debt payoff progress timeline
- Cash flow analysis
- Budget accuracy (planned vs actual)

### 8. Recurring Bills
- Bill calendar view
- Upcoming bills list
- Bill management (CRUD)

### 9. Forecasting
- Financial projection (6/12/24 months)
- Scenario modeling (income/expense changes)
- Goal timeline calculator
- Debt-free date impact analysis

### 10. Settings/Admin
- Profile management
- Budget categories customization
- CSV import column mapping presets
- App preferences (currency, date format)
- Theme toggle (system/dark/light)

## UI/UX

- **Theme:** System theme (auto dark/light) with manual toggle
- **Layout:** Collapsible sidebar navigation + main content area
- **Color scheme:** Indigo primary, green success, amber warning, red danger, slate neutrals
- **Design:** Data-rich financial dashboard, clean and professional
- **Quick actions:** Floating "Add Transaction" button on all pages

## RubyUI Components Used
Sidebar, Card, Table, Chart, Dialog, Form, Input, Select, Tabs, Badge, Progress, Alert, Accordion, Button, Breadcrumb, Tooltip, Calendar, Dropdown Menu, Theme Toggle, Separator, Avatar, Pagination

## Explicitly Not Building (YAGNI)
- Bank sync (Plaid integration)
- Multi-user support
- Mobile native app
- Credit score monitoring
- Investment analysis/tracking
- AI-powered insights
- Email notifications

## Transaction Input Methods
1. Manual entry (primary)
2. CSV import from bank statements (SolidQueue background processing)

## Debt Payoff Strategies
1. Snowball (smallest balance first)
2. Avalanche (highest interest first)
3. Side-by-side comparison showing savings difference
