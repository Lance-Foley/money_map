class Forecast < ApplicationRecord
  validates :name, presence: true
  validates :projection_months, presence: true, numericality: { in: 1..60 }

  def parsed_assumptions
    case assumptions
    when String then JSON.parse(assumptions)
    when Hash then assumptions
    else {}
    end
  end

  def parsed_results
    case results
    when String then JSON.parse(results)
    when Array then results
    else nil
    end
  end

  def generate_projection!
    results_data = []
    data = parsed_assumptions
    income = (data["monthly_income"] || 0).to_f
    expenses = (data["monthly_expenses"] || 0).to_f
    extra_debt = (data["extra_debt_payment"] || 0).to_f
    income_growth = (data["income_growth_rate"] || 0).to_f
    expense_growth = (data["expense_growth_rate"] || 0).to_f

    debts = Account.active.debts.map { |d|
      { id: d.id, name: d.name, balance: d.balance.to_f,
        rate: (d.interest_rate || 0).to_f, min_payment: (d.minimum_payment || 0).to_f }
    }
    current_savings = Account.active.assets.sum(:balance).to_f

    projection_months.times do |month|
      surplus = income - expenses - extra_debt
      debts.each do |debt|
        next if debt[:balance] <= 0
        monthly_interest = debt[:balance] * (debt[:rate] / 12.0)
        payment = debt[:min_payment] + (debt == debts.find { |d| d[:balance] > 0 } ? extra_debt : 0)
        principal = [payment - monthly_interest, debt[:balance]].min
        debt[:balance] = [debt[:balance] - principal, 0].max
      end

      current_savings += [surplus, 0].max
      total_debt = debts.sum { |d| d[:balance] }

      results_data << {
        month: month + 1,
        date: (Date.current + (month + 1).months).strftime("%Y-%m"),
        income: income.round(2),
        expenses: expenses.round(2),
        surplus: (income - expenses).round(2),
        total_debt: total_debt.round(2),
        savings: current_savings.round(2),
        net_worth: (current_savings - total_debt).round(2)
      }

      income *= (1 + income_growth / 12.0)
      expenses *= (1 + expense_growth / 12.0)
    end

    update!(results: results_data)
  end

  def debt_free_month
    parsed_results&.find { |r| r["total_debt"].to_f <= 0 }&.dig("month")
  end
end
