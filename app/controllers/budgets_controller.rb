# frozen_string_literal: true

class BudgetsController < ApplicationController
  def show
    @current_page = "Budget"
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month
    @period = BudgetPeriod.find_or_create_by!(year: year, month: month)
    @categories = BudgetCategory.ordered
    @items_by_category = @period.budget_items.includes(:budget_category).group_by(&:budget_category_id)
    @incomes = @period.incomes

    period_start = Date.new(year, month, 1)
    period_end = period_start.end_of_month
    @new_transactions = Transaction.uncategorized.by_date_range(period_start, period_end).chronological.includes(:account)
    @tracked_transactions = Transaction.where.not(budget_item_id: nil).by_date_range(period_start, period_end).chronological.includes(:account, :budget_item)

    render Views::Budgets::ShowView.new(
      period: @period, categories: @categories,
      items_by_category: @items_by_category, incomes: @incomes,
      new_transactions: @new_transactions,
      tracked_transactions: @tracked_transactions
    )
  end

  def copy_previous
    year = params[:year].to_i
    month = params[:month].to_i
    @period = BudgetPeriod.find_or_create_by!(year: year, month: month)
    previous = BudgetPeriod.where("year < ? OR (year = ? AND month < ?)", year, year, month)
      .order(:year, :month).last

    if previous
      @period.copy_from(previous)
      redirect_to budget_path(year: year, month: month), notice: "Budget copied from #{previous.display_name}."
    else
      redirect_to budget_path(year: year, month: month), alert: "No previous budget to copy from."
    end
  end
end
