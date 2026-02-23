# frozen_string_literal: true

class ActionPlanController < ApplicationController
  def show
    @current_page = "Action Plan"
    months = (params[:months] || 3).to_i.clamp(1, 12)

    # Auto-generate future months
    ActionPlanGenerator.new(months_ahead: months).generate!

    period_start = Date.current.beginning_of_month
    cash_flow_start = Date.current
    end_date = (period_start >> months) - 1.day

    @cash_flow = CashFlowCalculator.new(cash_flow_start, end_date).calculate
    @months = months

    @periods = BudgetPeriod.where(
      "year > ? OR (year = ? AND month >= ?)",
      period_start.year, period_start.year, period_start.month
    ).where(
      "year < ? OR (year = ? AND month <= ?)",
      end_date.year, end_date.year, end_date.month
    ).chronological.includes(budget_items: [:budget_category, :recurring_transaction, :account], incomes: [])

    # Group timeline events by month for the unified ledger view
    timeline_by_month = @cash_flow[:timeline].group_by { |e| [e[:date].year, e[:date].month] }

    @categories = BudgetCategory.ordered
    @accounts = Account.active.order(:name)

    # Sidebar data
    @active_accounts = Account.active.order(:account_type, :name)
    @current_period = BudgetPeriod.current.first
    @next_milestone = SavingsGoal.active.by_priority.first

    render Views::ActionPlan::ShowView.new(
      cash_flow: @cash_flow,
      periods: @periods,
      timeline_by_month: timeline_by_month,
      categories: @categories,
      accounts: @accounts,
      months: @months,
      active_accounts: @active_accounts,
      current_period: @current_period,
      next_milestone: @next_milestone
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
      :planned_amount, :expected_date, :rollover, :fund_goal, :account_id
    )
  end

  def income_params
    params.require(:income).permit(
      :budget_period_id, :source_name, :expected_amount,
      :pay_date, :recurring
    )
  end
end
