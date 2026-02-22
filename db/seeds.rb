# db/seeds.rb

puts "Seeding MoneyMap from CSV data..."

# ============================================
# 1. Admin User
# ============================================
admin = User.find_or_create_by!(email_address: "admin@moneymap.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "  Admin user: admin@moneymap.local / password123"

# ============================================
# 2. Budget Categories
# ============================================
categories_data = [
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
  { name: "Lifestyle", position: 11, icon: "smile", color: "#a855f7" },
  { name: "Income", position: 12, icon: "dollar-sign", color: "#22c55e" }
]
categories_data.each do |attrs|
  BudgetCategory.find_or_create_by!(name: attrs[:name]) do |cat|
    cat.assign_attributes(attrs)
  end
end
puts "  #{BudgetCategory.count} budget categories"

# ============================================
# 3. Load and analyze the CSV
# ============================================
csv_path = Rails.root.join("test/fixtures/files/sample_bank_transactions.csv")
csv_content = File.read(csv_path)

analyzer = SmartImportAnalyzer.new(
  csv_content,
  account_name: "Betterment Checking",
  institution_name: "Betterment"
)
analysis = analyzer.analyze

puts "  Analyzed CSV: #{analysis[:summary][:total_transactions]} transactions found"
puts "  Date range: #{analysis[:summary][:date_range][:start]} to #{analysis[:summary][:date_range][:end]}"
puts "  Monthly income avg: $#{'%.2f' % analysis[:summary][:monthly_income_avg]}"
puts "  Monthly expense avg: $#{'%.2f' % analysis[:summary][:monthly_expense_avg]}"

# ============================================
# 4. Create primary account (Betterment Checking)
# ============================================
checking = Account.find_or_create_by!(name: "Betterment Checking") do |a|
  a.account_type = :checking
  a.institution_name = "Betterment"
  a.balance = 3500.00
end
puts "  Created primary account: #{checking.name}"

# ============================================
# 5. Create detected sub-accounts
# ============================================
analysis[:detected_accounts].each do |acct_data|
  next if acct_data[:name].blank?

  account = Account.find_or_create_by!(name: acct_data[:name]) do |a|
    a.account_type = acct_data[:type] || :savings
    a.balance = 0
  end

  # Set realistic balances
  case acct_data[:name]
  when "Emergency Fund"
    account.update!(balance: 4500.00, institution_name: "Betterment")
  when "General Savings"
    account.update!(balance: 1200.00, institution_name: "Betterment")
  when "Apple Credit Card"
    account.update!(
      balance: 2100.00,
      institution_name: "Apple / Goldman Sachs",
      interest_rate: 0.2474,
      minimum_payment: 50.00,
      credit_limit: 6500.00
    )
  when "Chase Credit Card"
    account.update!(
      balance: 1800.00,
      institution_name: "Chase",
      interest_rate: 0.2199,
      minimum_payment: 45.00,
      credit_limit: 8000.00
    )
  end
end
puts "  #{Account.count} total accounts"

# ============================================
# 6. Create recurring transactions (expenses from CSV detection)
# ============================================
analysis[:recurring_bills].each do |bill_data|
  name = bill_data[:name]
  next if name.blank? || RecurringTransaction.exists?(name: name, direction: :expense)

  category = BudgetCategory.find_by(name: bill_data[:category])
  due_day = (bill_data[:due_day] || 1).to_i.clamp(1, 31)

  RecurringTransaction.create!(
    name: name,
    amount: bill_data[:amount] || 0,
    frequency: bill_data[:frequency] || :monthly,
    due_day: due_day,
    start_date: Date.new(Date.current.year, Date.current.month, [due_day, Date.current.end_of_month.day].min),
    budget_category: category,
    account: checking,
    direction: :expense,
    active: true,
    reminder_days_before: 3
  )
end

# Create recurring income transactions from CSV detection
analysis[:recurring_income].each do |inc_data|
  source_name = inc_data[:source_name]
  next if source_name.blank? || RecurringTransaction.exists?(name: source_name, direction: :income)

  freq = case inc_data[:frequency]&.to_sym
         when :weekly then :weekly
         when :biweekly then :biweekly
         when :monthly then :monthly
         else :monthly
         end

  start_date = Date.parse(inc_data[:start_date].to_s) rescue Date.current.beginning_of_month
  due_day = start_date.day.clamp(1, 31)

  RecurringTransaction.create!(
    name: source_name,
    amount: inc_data[:amount] || 0,
    frequency: freq,
    due_day: due_day,
    start_date: start_date,
    direction: :income,
    active: true
  )
end

puts "  #{RecurringTransaction.expenses.count} recurring expenses"
puts "  #{RecurringTransaction.incomes_only.count} recurring income"

# ============================================
# 7. Create budget periods and income entries
# ============================================
today = Date.current

# Create periods for each month covered by CSV + current month
analysis[:transactions].map { |t| Date.parse(t[:date].to_s) rescue nil }.compact
  .map { |d| [d.year, d.month] }.uniq
  .each do |(year, month)|
    period = BudgetPeriod.find_or_create_by!(year: year, month: month) do |p|
      p.status = (year == today.year && month == today.month) ? :active : :closed
    end
  end

# Ensure current month exists
current_period = BudgetPeriod.find_or_create_by!(year: today.year, month: today.month) do |p|
  p.status = :active
end

# Create income entries linked to recurring income transactions
RecurringTransaction.active.incomes_only.each do |rt|
  Income.find_or_create_by!(
    budget_period: current_period,
    source_name: rt.name,
    recurring_transaction: rt
  ) do |i|
    i.expected_amount = rt.amount
    i.received_amount = rt.amount
    i.pay_date = Date.new(today.year, today.month, [rt.due_day, today.end_of_month.day].min)
    i.recurring = true
    i.auto_generated = false
  end
end
puts "  #{Income.count} income entries"

# ============================================
# 8. Create budget items from spending data
# ============================================
analysis[:budget_suggestions].each do |suggestion|
  category = BudgetCategory.find_by(name: suggestion[:category])
  next unless category

  # Create budget items in current period
  next if current_period.budget_items.exists?(budget_category: category, name: suggestion[:category])

  current_period.budget_items.create!(
    budget_category: category,
    name: suggestion[:category],
    planned_amount: suggestion[:monthly_total] || 0,
    expected_date: Date.new(today.year, today.month, 1),
    account: checking
  )
end

# Also create budget items from recurring expense transactions
RecurringTransaction.active.expenses.each do |txn|
  next if current_period.budget_items.exists?(recurring_transaction: txn)

  range_start = Date.new(today.year, today.month, 1)
  range_end = range_start.end_of_month
  dates = txn.occurrences_in_range(range_start, range_end)

  dates.each do |occurrence_date|
    category = txn.budget_category || BudgetCategory.find_by(name: "Personal")
    current_period.budget_items.create!(
      name: txn.name,
      planned_amount: txn.amount,
      expected_date: occurrence_date,
      recurring_transaction: txn,
      budget_category: category,
      auto_generated: true,
      account: checking
    )
  end
end

current_period.recalculate_totals!
puts "  #{BudgetItem.count} budget items"

# ============================================
# 9. Import all transactions from CSV
# ============================================
analysis[:transactions].each do |txn|
  date = Date.parse(txn[:date].to_s) rescue nil
  next unless date

  amount = txn[:abs_amount] || txn[:amount].to_f.abs
  txn_type = case txn[:transaction_type]&.to_sym
             when :income then :income
             when :transfer then :transfer
             else :expense
             end

  Transaction.create!(
    account: checking,
    date: date,
    amount: amount,
    description: txn[:description],
    transaction_type: txn_type,
    imported: true
  )
end
puts "  #{Transaction.count} transactions imported"

# ============================================
# 10. Savings Goals
# ============================================
SavingsGoal.find_or_create_by!(name: "Emergency Fund") do |g|
  g.target_amount = 10000
  g.current_amount = 4500
  g.target_date = Date.current + 12.months
  g.category = :emergency_fund
  g.priority = 1
end

SavingsGoal.find_or_create_by!(name: "General Savings") do |g|
  g.target_amount = 5000
  g.current_amount = 1200
  g.target_date = Date.current + 18.months
  g.category = :general
  g.priority = 2
end
puts "  #{SavingsGoal.count} savings goals"

# ============================================
# 11. Net Worth Snapshots
# ============================================
total_assets = Account.active.assets.sum(:balance).to_f
total_liabilities = Account.active.debts.sum(:balance).to_f

3.downto(0) do |months_ago|
  date = (Date.current - months_ago.months).beginning_of_month
  next if NetWorthSnapshot.exists?(recorded_at: date)

  assets = total_assets - (months_ago * 300)
  liabilities = total_liabilities + (months_ago * 200)

  NetWorthSnapshot.create!(
    recorded_at: date,
    total_assets: assets,
    total_liabilities: liabilities,
    net_worth: assets - liabilities,
    breakdown: []
  )
end
puts "  #{NetWorthSnapshot.count} net worth snapshots"

# ============================================
# 12. Generate Action Plan (3 months ahead)
# ============================================
ActionPlanGenerator.new(months_ahead: 3).generate!
puts "  Action plan generated for next 3 months"

puts "\nSeeding complete!"
puts "Login: admin@moneymap.local / password123"
puts ""
puts "Summary:"
puts "  Accounts:              #{Account.count}"
puts "  Recurring Expenses:    #{RecurringTransaction.expenses.count}"
puts "  Recurring Income:      #{RecurringTransaction.incomes_only.count}"
puts "  Income Entries:        #{Income.count}"
puts "  Transactions:          #{Transaction.count}"
puts "  Budget Periods:        #{BudgetPeriod.count}"
puts "  Budget Items:          #{BudgetItem.count}"
