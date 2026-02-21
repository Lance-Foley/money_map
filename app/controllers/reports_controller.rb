# frozen_string_literal: true

class ReportsController < ApplicationController
  def index
    @current_page = "Reports"
    @period_range = (params[:months] || 12).to_i

    render Views::Reports::IndexView.new(
      income_vs_expenses: income_vs_expenses_data,
      spending_by_category: spending_by_category_data,
      net_worth_history: net_worth_data,
      debt_progress: debt_progress_data,
      budget_accuracy: budget_accuracy_data,
      period_range: @period_range
    )
  end

  private

  def income_vs_expenses_data
    BudgetPeriod.chronological.last(@period_range).map { |p|
      { label: p.display_name, income: (p.total_income || 0).to_f, expenses: (p.total_spent || 0).to_f }
    }
  end

  def spending_by_category_data
    period = BudgetPeriod.find_by(year: Date.current.year, month: Date.current.month)
    return [] unless period

    period.budget_items
      .joins(:budget_category)
      .group("budget_categories.name", "budget_categories.color")
      .sum(:spent_amount)
      .map { |(name, color), amount| { category: name, amount: amount.to_f, color: color } }
      .sort_by { |h| -h[:amount] }
  end

  def net_worth_data
    NetWorthSnapshot.recent(@period_range).map { |s|
      { date: s.recorded_at.strftime("%b %Y"), net_worth: s.net_worth.to_f,
        assets: s.total_assets.to_f, liabilities: s.total_liabilities.to_f }
    }
  end

  def debt_progress_data
    Account.active.debts.map { |a|
      original = (a.original_balance || a.balance).to_f
      current = a.balance.to_f
      progress = original > 0 ? ((original - current) / original * 100).round(1) : 0
      { name: a.name, current: current, original: original, progress: progress }
    }
  end

  def budget_accuracy_data
    BudgetPeriod.chronological.last(@period_range).map { |p|
      planned = (p.total_planned || 0).to_f
      actual = (p.total_spent || 0).to_f
      accuracy = planned > 0 ? (actual / planned * 100).round(1) : 0
      { period: p.display_name, planned: planned, actual: actual, accuracy: accuracy }
    }
  end
end
