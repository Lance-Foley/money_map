# frozen_string_literal: true

class IncomesController < ApplicationController
  def create
    @income = Income.new(income_params)
    if @income.save
      period = @income.budget_period
      redirect_to budget_path(year: period.year, month: period.month), notice: "Income added."
    else
      period = BudgetPeriod.find(income_params[:budget_period_id])
      redirect_to budget_path(year: period.year, month: period.month), alert: @income.errors.full_messages.join(", ")
    end
  end

  def update
    @income = Income.find(params[:id])
    if @income.update(income_params)
      period = @income.budget_period
      redirect_to budget_path(year: period.year, month: period.month), notice: "Income updated."
    else
      period = @income.budget_period
      redirect_to budget_path(year: period.year, month: period.month), alert: @income.errors.full_messages.join(", ")
    end
  end

  def destroy
    @income = Income.find(params[:id])
    period = @income.budget_period
    @income.destroy
    redirect_to budget_path(year: period.year, month: period.month), notice: "Income removed."
  end

  private

  def income_params
    params.require(:income).permit(:budget_period_id, :source_name, :expected_amount, :received_amount, :pay_date, :recurring, :frequency, :start_date, :custom_interval_value, :custom_interval_unit)
  end
end
