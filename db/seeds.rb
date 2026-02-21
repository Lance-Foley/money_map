# db/seeds.rb

puts "Seeding MoneyMap..."

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
  { name: "Lifestyle", position: 11, icon: "smile", color: "#a855f7" }
]
categories = {}
categories_data.each do |attrs|
  categories[attrs[:name]] = BudgetCategory.find_or_create_by!(name: attrs[:name]) do |cat|
    cat.assign_attributes(attrs)
  end
end
puts "  #{BudgetCategory.count} budget categories"

# ============================================
# 3. Financial Accounts
# ============================================
checking = Account.find_or_create_by!(name: "Primary Checking") do |a|
  a.account_type = :checking
  a.institution_name = "Chase"
  a.balance = 4250.00
end

savings_acct = Account.find_or_create_by!(name: "Emergency Savings") do |a|
  a.account_type = :savings
  a.institution_name = "Ally Bank"
  a.balance = 8500.00
  a.interest_rate = 0.045
end

investment = Account.find_or_create_by!(name: "401k") do |a|
  a.account_type = :investment
  a.institution_name = "Fidelity"
  a.balance = 45000.00
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
  a.institution_name = "Local Credit Union"
  a.balance = 12500.00
  a.interest_rate = 0.0549
  a.minimum_payment = 325.00
  a.original_balance = 22000.00
end

student_loan = Account.find_or_create_by!(name: "Student Loans") do |a|
  a.account_type = :loan
  a.institution_name = "Navient"
  a.balance = 18000.00
  a.interest_rate = 0.0650
  a.minimum_payment = 250.00
  a.original_balance = 35000.00
end

mortgage = Account.find_or_create_by!(name: "Home Mortgage") do |a|
  a.account_type = :mortgage
  a.institution_name = "Wells Fargo"
  a.balance = 235000.00
  a.interest_rate = 0.0399
  a.minimum_payment = 1150.00
  a.original_balance = 275000.00
end

puts "  #{Account.count} accounts"

# ============================================
# 4. Budget Periods (Last 3 months + current)
# ============================================
today = Date.current
months = [
  [(today - 3.months).year, (today - 3.months).month],
  [(today - 2.months).year, (today - 2.months).month],
  [(today - 1.month).year, (today - 1.month).month],
  [today.year, today.month]
]

# Each item has [name, planned_amount, expected_day_of_month]
budget_items_template = [
  { category: "Giving", items: [["Tithing", 500, 1], ["Charity", 100, 1]] },
  { category: "Savings", items: [["Emergency Fund", 500, 1], ["Vacation Fund", 200, 1]] },
  { category: "Housing", items: [["Mortgage", 1150, 1], ["Home Insurance", 125, 1], ["Home Repairs", 100, 15]] },
  { category: "Utilities", items: [["Electric", 150, 15], ["Water", 60, 20], ["Internet", 80, 10], ["Phone", 85, 12]] },
  { category: "Food", items: [["Groceries", 600, 7], ["Restaurants", 150, 15]] },
  { category: "Transportation", items: [["Gas", 200, 7], ["Car Insurance", 120, 5], ["Car Maintenance", 50, 15]] },
  { category: "Insurance", items: [["Health Insurance", 350, 1], ["Life Insurance", 45, 15]] },
  { category: "Health", items: [["Doctor/Dental", 50, 15], ["Gym", 40, 1]] },
  { category: "Debt", items: [["Credit Card Payment", 200, 15], ["Car Payment", 325, 15], ["Student Loan Payment", 250, 15]] },
  { category: "Personal", items: [["Clothing", 100, 10], ["Haircut", 30, 20]] },
  { category: "Lifestyle", items: [["Subscriptions", 50, 8], ["Entertainment", 100, 15], ["Hobbies", 75, 20]] }
]

months.each_with_index do |(year, month), idx|
  period = BudgetPeriod.find_or_create_by!(year: year, month: month) do |p|
    p.status = idx < months.length - 1 ? :closed : :active
  end

  # Add income - biweekly primary job (two paychecks per month)
  Income.find_or_create_by!(budget_period: period, source_name: "Primary Job", pay_date: Date.new(year, month, 14)) do |i|
    i.expected_amount = 3250
    i.received_amount = 3250
    i.recurring = true
    i.frequency = :biweekly
    i.start_date = Date.new(2026, 1, 2)
    i.auto_generated = false
  end

  last_day = Date.new(year, month, -1).day
  Income.find_or_create_by!(budget_period: period, source_name: "Primary Job", pay_date: Date.new(year, month, [28, last_day].min)) do |i|
    i.expected_amount = 3250
    i.received_amount = 3250
    i.recurring = true
    i.frequency = :biweekly
    i.start_date = Date.new(2026, 1, 16)
    i.auto_generated = false
  end

  Income.find_or_create_by!(budget_period: period, source_name: "Side Hustle") do |i|
    i.expected_amount = 800
    i.received_amount = [700, 800, 900, 850][idx]
    i.pay_date = Date.new(year, month, [28, last_day].min)
    i.recurring = true
    i.frequency = :monthly
    i.start_date = Date.new(2026, 1, 28)
    i.auto_generated = false
  end

  # Add budget items with realistic variation
  budget_items_template.each do |group|
    cat = categories[group[:category]]
    next unless cat

    group[:items].each do |name, planned, expected_day|
      spent = (planned * (0.85 + rand * 0.3)).round(2)
      spent = [spent, 0].max
      days_in_month = Date.new(year, month, -1).day
      safe_day = [expected_day || 1, days_in_month].min

      BudgetItem.find_or_create_by!(budget_period: period, budget_category: cat, name: name) do |item|
        item.planned_amount = planned
        item.spent_amount = idx < months.length - 1 ? spent : (spent * 0.6).round(2) # Current month partially spent
        item.expected_date = Date.new(year, month, safe_day)
        item.rollover = name.include?("Fund")
        item.fund_goal = name.include?("Fund") ? planned * 12 : nil
        item.fund_balance = name.include?("Fund") ? planned * idx : nil
        item.account = checking
      end
    end
  end

  # Recalculate totals
  period.recalculate_totals!
end

puts "  #{BudgetPeriod.count} budget periods with items"

# ============================================
# 5. Transactions (Last 3 months of realistic data)
# ============================================
transaction_templates = [
  { desc: "Kroger", merchant: "Kroger", type: :expense, amount_range: 45..120, category: "Groceries", freq: 8 },
  { desc: "Shell Gas Station", merchant: "Shell", type: :expense, amount_range: 35..65, category: "Gas", freq: 4 },
  { desc: "Netflix", merchant: "Netflix", type: :expense, amount_range: 15..15, category: "Subscriptions", freq: 1 },
  { desc: "Spotify", merchant: "Spotify", type: :expense, amount_range: 11..11, category: "Subscriptions", freq: 1 },
  { desc: "Amazon", merchant: "Amazon", type: :expense, amount_range: 15..80, category: "Clothing", freq: 2 },
  { desc: "Chipotle", merchant: "Chipotle", type: :expense, amount_range: 12..18, category: "Restaurants", freq: 3 },
  { desc: "Starbucks", merchant: "Starbucks", type: :expense, amount_range: 5..8, category: "Restaurants", freq: 5 },
  { desc: "Electric Bill", merchant: "Duke Energy", type: :expense, amount_range: 120..180, category: "Electric", freq: 1 },
  { desc: "Water Bill", merchant: "City Water", type: :expense, amount_range: 50..70, category: "Water", freq: 1 },
  { desc: "Internet Bill", merchant: "Spectrum", type: :expense, amount_range: 80..80, category: "Internet", freq: 1 },
  { desc: "Phone Bill", merchant: "T-Mobile", type: :expense, amount_range: 85..85, category: "Phone", freq: 1 },
  { desc: "Gym Membership", merchant: "Planet Fitness", type: :expense, amount_range: 40..40, category: "Gym", freq: 1 },
  { desc: "Target", merchant: "Target", type: :expense, amount_range: 25..75, category: "Clothing", freq: 2 },
  { desc: "Paycheck", merchant: "Employer", type: :income, amount_range: 3250..3250, category: nil, freq: 2 },
  { desc: "Freelance Payment", merchant: "Client", type: :income, amount_range: 350..450, category: nil, freq: 2 }
]

months.each do |(year, month)|
  period = BudgetPeriod.find_by(year: year, month: month)
  days_in_month = Date.new(year, month, -1).day
  max_day = (year == today.year && month == today.month) ? [today.day, days_in_month].min : days_in_month

  transaction_templates.each do |tmpl|
    tmpl[:freq].times do |_i|
      day = rand(1..max_day)
      amount = rand(tmpl[:amount_range])

      # Find matching budget item
      budget_item = nil
      if tmpl[:category] && period
        budget_item = period.budget_items.find_by(name: tmpl[:category])
      end

      Transaction.create!(
        account: tmpl[:type] == :income ? checking : [checking, credit_card].sample,
        budget_item: budget_item,
        date: Date.new(year, month, day),
        amount: amount,
        description: tmpl[:desc],
        merchant: tmpl[:merchant],
        transaction_type: tmpl[:type]
      )
    end
  end
end

puts "  #{Transaction.count} transactions"

# ============================================
# 6. Recurring Bills
# ============================================
bills = [
  # Monthly bills with start_date based on due_day
  { name: "Mortgage", amount: 1150, due_day: 1, frequency: :monthly, start_date: Date.new(2026, 1, 1), category: "Housing" },
  { name: "Car Insurance", amount: 120, due_day: 5, frequency: :monthly, start_date: Date.new(2026, 1, 5), category: "Transportation" },
  { name: "Electric", amount: 150, due_day: 15, frequency: :monthly, start_date: Date.new(2026, 1, 15), category: "Utilities" },
  { name: "Water", amount: 60, due_day: 20, frequency: :monthly, start_date: Date.new(2026, 1, 20), category: "Utilities" },
  { name: "Internet", amount: 80, due_day: 10, frequency: :monthly, start_date: Date.new(2026, 1, 10), category: "Utilities" },
  { name: "Phone", amount: 85, due_day: 12, frequency: :monthly, start_date: Date.new(2026, 1, 12), category: "Utilities" },
  { name: "Netflix", amount: 15, due_day: 8, frequency: :monthly, start_date: Date.new(2026, 1, 8), category: "Lifestyle" },
  { name: "Spotify", amount: 11, due_day: 8, frequency: :monthly, start_date: Date.new(2026, 1, 8), category: "Lifestyle" },
  { name: "Gym", amount: 40, due_day: 1, frequency: :monthly, start_date: Date.new(2026, 1, 1), category: "Health" },
  { name: "Health Insurance", amount: 350, due_day: 1, frequency: :monthly, start_date: Date.new(2026, 1, 1), category: "Insurance" },
  { name: "Life Insurance", amount: 45, due_day: 15, frequency: :monthly, start_date: Date.new(2026, 1, 15), category: "Insurance" },
  # Weekly bill
  { name: "House Cleaning", amount: 75, due_day: 6, frequency: :weekly, start_date: Date.new(2026, 1, 6), category: "Housing" },
  # Biweekly bill
  { name: "Lawn Service", amount: 50, due_day: 3, frequency: :biweekly, start_date: Date.new(2026, 1, 3), category: "Housing" },
  # Custom frequency: pest control every 3 months
  { name: "Pest Control", amount: 120, due_day: 15, frequency: :custom, start_date: Date.new(2026, 1, 15),
    custom_interval_value: 3, custom_interval_unit: 2, category: "Housing" }
]

bills.each do |bill_data|
  cat = categories[bill_data[:category]]
  RecurringBill.find_or_create_by!(name: bill_data[:name]) do |b|
    b.amount = bill_data[:amount]
    b.due_day = bill_data[:due_day]
    b.frequency = bill_data[:frequency]
    b.start_date = bill_data[:start_date]
    b.budget_category = cat
    b.account = checking
    b.active = true
    b.reminder_days_before = 3
    b.custom_interval_value = bill_data[:custom_interval_value] if bill_data[:custom_interval_value]
    b.custom_interval_unit = bill_data[:custom_interval_unit] if bill_data[:custom_interval_unit]
  end
end

puts "  #{RecurringBill.count} recurring bills"

# ============================================
# 7. Savings Goals
# ============================================
SavingsGoal.find_or_create_by!(name: "Emergency Fund") do |g|
  g.target_amount = 20000
  g.current_amount = 8500
  g.target_date = Date.current + 18.months
  g.category = :emergency_fund
  g.priority = 1
end

SavingsGoal.find_or_create_by!(name: "Vacation Fund") do |g|
  g.target_amount = 3000
  g.current_amount = 1200
  g.target_date = Date.current + 6.months
  g.category = :sinking_fund
  g.priority = 2
end

SavingsGoal.find_or_create_by!(name: "New Car Down Payment") do |g|
  g.target_amount = 10000
  g.current_amount = 2500
  g.target_date = Date.current + 24.months
  g.category = :general
  g.priority = 3
end

SavingsGoal.find_or_create_by!(name: "Christmas Fund") do |g|
  g.target_amount = 1500
  g.current_amount = 400
  g.target_date = Date.new(Date.current.year, 12, 1)
  g.category = :sinking_fund
  g.priority = 4
end

puts "  #{SavingsGoal.count} savings goals"

# ============================================
# 8. Net Worth Snapshots (Last 6 months)
# ============================================
6.downto(0) do |months_ago|
  date = (Date.current - months_ago.months).beginning_of_month
  next if NetWorthSnapshot.exists?(recorded_at: date)

  # Simulate improving finances over time
  asset_base = 50000 + (6 - months_ago) * 1500
  liability_base = 270000 - (6 - months_ago) * 800

  NetWorthSnapshot.create!(
    recorded_at: date,
    total_assets: asset_base,
    total_liabilities: liability_base,
    net_worth: asset_base - liability_base,
    breakdown: []
  )
end

puts "  #{NetWorthSnapshot.count} net worth snapshots"

# ============================================
# 9. Debt Payments (Historical)
# ============================================
3.downto(1) do |months_ago|
  date = Date.current - months_ago.months

  DebtPayment.find_or_create_by!(account: credit_card, payment_date: date.beginning_of_month + 14.days) do |p|
    p.amount = 200
    p.principal_portion = 148
    p.interest_portion = 52
  end

  DebtPayment.find_or_create_by!(account: car_loan, payment_date: date.beginning_of_month + 14.days) do |p|
    p.amount = 325
    p.principal_portion = 270
    p.interest_portion = 55
  end

  DebtPayment.find_or_create_by!(account: student_loan, payment_date: date.beginning_of_month + 14.days) do |p|
    p.amount = 250
    p.principal_portion = 152
    p.interest_portion = 98
  end
end

puts "  #{DebtPayment.count} debt payments"

puts "\nSeeding complete!"
puts "Login: admin@moneymap.local / password123"
