# frozen_string_literal: true

class RecurringBillsController < ApplicationController
  before_action :set_bill, only: [ :show, :edit, :update, :destroy ]

  def index
    @current_page = "Recurring Bills"
    @bills = RecurringBill.active.order(:next_due_date)
    render Views::RecurringBills::IndexView.new(bills: @bills)
  end

  def show
    @current_page = "Recurring Bills"
    redirect_to recurring_bills_path
  end

  def new
    @current_page = "Recurring Bills"
    render Views::RecurringBills::FormView.new(
      bill: RecurringBill.new,
      accounts: Account.active,
      categories: BudgetCategory.ordered
    )
  end

  def create
    @current_page = "Recurring Bills"
    @bill = RecurringBill.new(bill_params)
    if @bill.save
      redirect_to recurring_bills_path, notice: "Recurring bill created."
    else
      render Views::RecurringBills::FormView.new(
        bill: @bill, accounts: Account.active, categories: BudgetCategory.ordered
      ), status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "Recurring Bills"
    render Views::RecurringBills::FormView.new(
      bill: @bill, accounts: Account.active, categories: BudgetCategory.ordered
    )
  end

  def update
    @current_page = "Recurring Bills"
    if @bill.update(bill_params)
      redirect_to recurring_bills_path, notice: "Recurring bill updated."
    else
      render Views::RecurringBills::FormView.new(
        bill: @bill, accounts: Account.active, categories: BudgetCategory.ordered
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @bill.destroy
    redirect_to recurring_bills_path, notice: "Recurring bill deleted."
  end

  private

  def set_bill
    @bill = RecurringBill.find(params[:id])
  end

  def bill_params
    params.require(:recurring_bill).permit(:name, :amount, :account_id, :budget_category_id, :due_day, :frequency, :auto_create_transaction, :reminder_days_before, :active)
  end
end
