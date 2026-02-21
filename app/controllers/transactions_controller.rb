# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :edit, :update, :destroy ]

  def index
    @current_page = "Transactions"
    @transactions = Transaction.chronological
    @transactions = @transactions.where(account_id: params[:account_id]) if params[:account_id].present?
    @transactions = @transactions.uncategorized if params[:uncategorized] == "true"
    @transactions = @transactions.by_date_range(params[:start_date], params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    @transactions = @transactions.where("description LIKE ?", "%#{params[:search]}%") if params[:search].present?

    render Views::Transactions::IndexView.new(
      transactions: @transactions.includes(:account, :budget_item).limit(100),
      accounts: Account.active,
      budget_items: current_period_items
    )
  end

  def new
    @current_page = "Transactions"
    render Views::Transactions::FormView.new(
      transaction: Transaction.new,
      accounts: Account.active,
      budget_items: current_period_items
    )
  end

  def create
    @current_page = "Transactions"
    @transaction = Transaction.new(transaction_params)
    if @transaction.save
      redirect_to transactions_path, notice: "Transaction added."
    else
      render Views::Transactions::FormView.new(
        transaction: @transaction, accounts: Account.active, budget_items: current_period_items
      ), status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "Transactions"
    render Views::Transactions::FormView.new(
      transaction: @transaction, accounts: Account.active, budget_items: current_period_items
    )
  end

  def update
    @current_page = "Transactions"
    if @transaction.update(transaction_params)
      redirect_to transactions_path, notice: "Transaction updated."
    else
      render Views::Transactions::FormView.new(
        transaction: @transaction, accounts: Account.active, budget_items: current_period_items
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction deleted."
  end

  def bulk_categorize
    if params[:transaction_ids].present? && params[:budget_item_id].present?
      Transaction.where(id: params[:transaction_ids]).update_all(budget_item_id: params[:budget_item_id])
      redirect_to transactions_path, notice: "Transactions categorized."
    else
      redirect_to transactions_path, alert: "Please select transactions and a category."
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:account_id, :budget_item_id, :date, :amount, :description, :merchant, :notes, :transaction_type)
  end

  def current_period_items
    period = BudgetPeriod.find_by(year: Date.current.year, month: Date.current.month)
    period&.budget_items&.includes(:budget_category) || []
  end
end
