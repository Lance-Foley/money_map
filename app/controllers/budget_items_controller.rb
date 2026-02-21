# frozen_string_literal: true

class BudgetItemsController < ApplicationController
  def create
    @budget_item = BudgetItem.new(budget_item_params)
    if @budget_item.save
      period = @budget_item.budget_period
      redirect_to budget_path(year: period.year, month: period.month), notice: "Budget item added."
    else
      period = BudgetPeriod.find(budget_item_params[:budget_period_id])
      redirect_to budget_path(year: period.year, month: period.month), alert: @budget_item.errors.full_messages.join(", ")
    end
  end

  def update
    @budget_item = BudgetItem.find(params[:id])
    if @budget_item.update(budget_item_params)
      period = @budget_item.budget_period
      redirect_to budget_path(year: period.year, month: period.month), notice: "Budget item updated."
    else
      period = @budget_item.budget_period
      redirect_to budget_path(year: period.year, month: period.month), alert: @budget_item.errors.full_messages.join(", ")
    end
  end

  def destroy
    @budget_item = BudgetItem.find(params[:id])
    period = @budget_item.budget_period
    @budget_item.destroy
    redirect_to budget_path(year: period.year, month: period.month), notice: "Budget item removed."
  end

  private

  def budget_item_params
    params.require(:budget_item).permit(:budget_period_id, :budget_category_id, :name, :planned_amount, :rollover, :fund_goal)
  end
end
