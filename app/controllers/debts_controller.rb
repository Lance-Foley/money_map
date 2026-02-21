# frozen_string_literal: true

class DebtsController < ApplicationController
  def index
    @current_page = "Debt Payoff"
    @debt_accounts = Account.active.debts.order(:balance)
    @extra_payment = params[:extra_payment]&.to_f || 0

    debts_data = @debt_accounts.map { |a|
      { name: a.name, balance: a.balance.to_f, rate: (a.interest_rate || 0).to_f, min_payment: (a.minimum_payment || 0).to_f }
    }

    @comparison = debts_data.any? ? DebtCalculator.compare(debts_data, extra_payment: @extra_payment) : nil

    render Views::Debts::IndexView.new(
      accounts: @debt_accounts,
      comparison: @comparison,
      extra_payment: @extra_payment
    )
  end

  def show
    @current_page = "Debt Payoff"
    @account = Account.find(params[:id])
    @payments = DebtPayment.for_account(@account).chronological
    render Views::Debts::ShowView.new(account: @account, payments: @payments)
  end
end
