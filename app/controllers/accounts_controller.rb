# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @current_page = "Accounts"
    @accounts = Account.active.order(:account_type, :name)

    asset_accounts = @accounts.select(&:asset?)
    liability_accounts = @accounts.select(&:debt?)

    total_assets = asset_accounts.sum(&:balance)
    total_liabilities = liability_accounts.sum(&:balance)

    bank_accounts = asset_accounts.select { |a| a.checking? || a.savings? }
    investments = asset_accounts.select(&:investment?)
    credit_cards = liability_accounts.select(&:credit_card?)
    loans = liability_accounts.select(&:loan?)
    mortgages = liability_accounts.select(&:mortgage?)

    render Views::Accounts::IndexView.new(
      accounts: @accounts,
      bank_accounts: bank_accounts,
      investments: investments,
      credit_cards: credit_cards,
      loans: loans,
      mortgages: mortgages,
      total_assets: total_assets,
      total_liabilities: total_liabilities
    )
  end

  def show
    @current_page = "Accounts"
    @transactions = @account.transactions.chronological.limit(50)
    render Views::Accounts::ShowView.new(account: @account, transactions: @transactions)
  end

  def new
    @current_page = "Accounts"
    render Views::Accounts::FormView.new(account: Account.new)
  end

  def create
    @current_page = "Accounts"
    @account = Account.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account created."
    else
      render Views::Accounts::FormView.new(account: @account), status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "Accounts"
    render Views::Accounts::FormView.new(account: @account)
  end

  def update
    @current_page = "Accounts"
    if @account.update(account_params)
      redirect_to @account, notice: "Account updated."
    else
      render Views::Accounts::FormView.new(account: @account), status: :unprocessable_entity
    end
  end

  def destroy
    @account.update!(active: false)
    redirect_to accounts_path, notice: "Account deactivated."
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :account_type, :institution_name, :balance, :interest_rate, :minimum_payment, :credit_limit, :original_balance)
  end
end
