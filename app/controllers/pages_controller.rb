# frozen_string_literal: true

class PagesController < ApplicationController
  def dashboard
    @current_page = "Dashboard"
    current_period = BudgetPeriod.find_by(year: Date.current.year, month: Date.current.month)

    render Views::Pages::DashboardView.new(
      period: current_period,
      left_to_budget: current_period&.left_to_budget || 0,
      debt_comparison: calculate_debt_comparison,
      monthly_cash_flow: calculate_cash_flow(current_period),
      upcoming_bills: RecurringBill.active.where("next_due_date >= ? AND next_due_date <= ?", Date.current, Date.current + 7.days).order(:next_due_date),
      net_worth: calculate_net_worth,
      recent_transactions: Transaction.chronological.limit(5),
      savings_goals: SavingsGoal.active.by_priority.limit(3)
    )
  end

  private

  def calculate_debt_comparison
    debts = Account.active.debts.map { |a|
      { name: a.name, balance: a.balance.to_f, rate: (a.interest_rate || 0).to_f, min_payment: (a.minimum_payment || 0).to_f }
    }
    return nil if debts.empty?
    DebtCalculator.compare(debts)
  end

  def calculate_cash_flow(period)
    {
      income: (period&.total_income || 0).to_f,
      spent: (period&.total_spent || 0).to_f,
      remaining: ((period&.total_income || 0) - (period&.total_spent || 0)).to_f
    }
  end

  def calculate_net_worth
    current = NetWorthSnapshot.chronological.last
    previous = NetWorthSnapshot.chronological.offset(1).last
    {
      current: current&.net_worth&.to_f || (Account.active.assets.sum(:balance) - Account.active.debts.sum(:balance)).to_f,
      previous: previous&.net_worth&.to_f || 0,
      trend: current && previous ? (current.net_worth > previous.net_worth ? :up : :down) : :flat
    }
  end
end
