# frozen_string_literal: true

class RecurringTransactionsController < ApplicationController
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @current_page = "Recurring"
    @transactions = RecurringTransaction.active.order(:next_due_date)
    render Views::RecurringTransactions::IndexView.new(transactions: @transactions)
  end

  def show
    @current_page = "Recurring"
    redirect_to recurring_transactions_path
  end

  def new
    @current_page = "Recurring"
    render Views::RecurringTransactions::FormView.new(
      transaction: RecurringTransaction.new,
      accounts: Account.active,
      categories: BudgetCategory.ordered
    )
  end

  def create
    @current_page = "Recurring"
    @transaction = RecurringTransaction.new(transaction_params)
    if @transaction.save
      redirect_to recurring_transactions_path, notice: "Recurring transaction created."
    else
      render Views::RecurringTransactions::FormView.new(
        transaction: @transaction, accounts: Account.active, categories: BudgetCategory.ordered
      ), status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "Recurring"
    render Views::RecurringTransactions::FormView.new(
      transaction: @transaction, accounts: Account.active, categories: BudgetCategory.ordered
    )
  end

  def update
    @current_page = "Recurring"
    if @transaction.update(transaction_params)
      redirect_to recurring_transactions_path, notice: "Recurring transaction updated."
    else
      render Views::RecurringTransactions::FormView.new(
        transaction: @transaction, accounts: Account.active, categories: BudgetCategory.ordered
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to recurring_transactions_path, notice: "Recurring transaction deleted."
  end

  private

  def set_transaction
    @transaction = RecurringTransaction.find(params[:id])
  end

  def transaction_params
    params.require(:recurring_transaction).permit(:name, :amount, :account_id, :budget_category_id, :due_day, :frequency, :start_date, :custom_interval_value, :custom_interval_unit, :auto_create_transaction, :reminder_days_before, :active, :direction)
  end
end
