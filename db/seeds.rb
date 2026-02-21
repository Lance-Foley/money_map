# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.find_or_create_by!(email_address: "admin@moneymap.local") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end
puts "Admin user created: admin@moneymap.local / password123"

# Budget Categories
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
puts "Budget categories created: #{BudgetCategory.count} categories"
