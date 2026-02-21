# Action Plan & Flexible Frequencies - Design Document

**Date:** 2026-02-21
**Status:** Approved

## Overview

Two features that transform MoneyMap from a budgeting tool into a true financial planning app:

1. **Action Plan** — MoneyMax-style chronological cash flow view with multi-month forward projection
2. **Flexible Recurring Frequencies** — Customizable scheduling for bills and income

## Feature 1: Action Plan (Cash Flow Calendar)

### Concept

The action plan auto-generates real `BudgetPeriod`, `BudgetItem`, and `Income` records for 3 months forward (adjustable up to 12) based on recurring bills and recurring income. Each generated item is a real, editable record. Change one month's amount without affecting others. Add one-off items to any month.

Two views of the same data:
- **Action Plan** = MoneyMax-style. Chronological, cash-flow focused, multi-month. Add/edit items for any month.
- **Budget** = EveryDollar-style. Category-based, single month, drag-and-drop transactions into budget items.

### Data Changes

**budget_items table — new columns:**
- `expected_date` (date) — when this expense is expected to hit
- `recurring_bill_id` (integer, FK, nullable) — which recurring bill generated this item
- `auto_generated` (boolean, default: false) — marks items created by the action plan generator

**incomes table — new columns:**
- `auto_generated` (boolean, default: false) — marks income created by the action plan generator
- `recurring_source_id` (integer, nullable) — references the original recurring income entry that spawned this one
- `pay_date` becomes effectively required for action plan items

### ActionPlanGenerator Service

Generates future months from recurring sources. Idempotent — safe to re-run.

1. Looks at all active recurring bills and recurring income
2. For each future month in the lookahead window (default 3):
   - Creates a `BudgetPeriod` if one doesn't exist
   - For each recurring bill: creates a `BudgetItem` with `expected_date`, `recurring_bill_id`, `auto_generated: true` — only if one doesn't already exist for that bill+period combo
   - For each recurring income: creates an `Income` record — only if one doesn't already exist for that source+period combo
3. Never overwrites edited items — once generated, they're yours to modify

### CashFlowCalculator Service

Builds the running balance timeline.

1. Takes a date range (one or more months)
2. Starts with current total checking/savings account balance
3. Walks through all income and budget items chronologically by expected_date/pay_date
4. Calculates running balance at each event
5. Returns timeline data + flags dates where balance goes negative
6. Calculates month-end surplus/deficit for each month

### Controller & Routes

```ruby
# Action Plan
get "action_plan", to: "action_plan#show", as: :action_plan
post "action_plan/generate", to: "action_plan#generate", as: :generate_action_plan
```

### View Layout

**Top:** Line chart (Chart.js) showing running balance across all visible months. Green above zero, red below.

**Month sections:** Each month is a collapsible section:
- Income items (green highlight) with dates and amounts
- Expense/budget items with dates and amounts
- Month subtotal: total income, total expenses, surplus/deficit
- "Add Item" button — add budget items or one-off income to any month
- Each item row: date | name | type badge (recurring/one-off) | amount (inline editable) | running balance

Items from recurring sources show a link icon. One-off items show no icon.

**Controls:**
- Months lookahead selector (3/6/12 months)
- "Regenerate" button to add new recurring items if bills/income changed

**Sidebar nav:** "Action Plan" between Budget and Transactions.

### Interaction with Budget View

Budget items created/edited via the action plan appear in the Budget view grouped by category. Transactions dragged into budget items in the Budget view update `spent_amount` which the action plan also reflects. Same underlying data, two presentation styles.

## Feature 2: Flexible Recurring Frequencies

### Unified Frequency Model

Applies to both `RecurringBill` and `Income` models.

**Expanded frequency enum:**
```
weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3,
quarterly: 4, semi_annual: 5, annual: 6, custom: 7
```

**New columns (both tables):**
- `custom_interval_value` (integer, nullable) — e.g., 3
- `custom_interval_unit` (integer enum, nullable) — days: 0, weeks: 1, months: 2, years: 3
- `start_date` (date) — anchor for all frequency calculations

### Schedulable Concern

Shared module included by both `RecurringBill` and `Income`:

- `next_occurrence_after(date)` — next occurrence after a given date
- `occurrences_in_range(start_date, end_date)` — all dates within a range
- `schedule_description` — human-readable: "Every 3 months starting Mar 15"

### Calculation Logic

| Frequency | Calculation |
|-----------|------------|
| weekly | Every 7 days from start_date |
| biweekly | Every 14 days from start_date |
| semimonthly | start_date.day and start_date.day + 15 each month |
| monthly | Same day each month from start_date |
| quarterly | Every 3 months from start_date |
| semi_annual | Every 6 months from start_date |
| annual | Same date each year from start_date |
| custom | start_date + (N * interval_value * interval_unit) |

### Income Model Migration

Old enum: `one_time: 0, weekly: 1, biweekly: 2, semimonthly: 3, monthly: 4`
New enum: matches RecurringBill. Non-recurring income is indicated by `recurring: false` (existing column).

### UI

Frequency select dropdown with named presets. When "Custom" is selected, two fields appear: interval value (number) + unit (dropdown). All frequencies show a start_date date picker.

## Explicitly Not Building

- Drag-and-drop reordering within the action plan (items sort by date)
- Notifications/alerts for negative balance projections (just visual highlighting)
- Auto-pay integration
- Recurring bill amount history tracking
