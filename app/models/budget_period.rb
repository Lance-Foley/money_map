class BudgetPeriod < ApplicationRecord
  has_many :budget_items, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :debt_payments

  enum :status, { draft: 0, active: 1, closed: 2 }

  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, uniqueness: { scope: :month }

  scope :chronological, -> { order(:year, :month) }
  scope :current, -> { where(year: Date.current.year, month: Date.current.month) }

  def left_to_budget
    (total_income || 0) - (total_planned || 0)
  end

  def zero_based?
    left_to_budget.zero?
  end

  def display_name
    Date.new(year, month, 1).strftime("%B %Y")
  end

  def copy_from(other_period)
    other_period.budget_items.each do |item|
      budget_items.create!(
        budget_category: item.budget_category,
        name: item.name,
        planned_amount: item.planned_amount,
        rollover: item.rollover,
        fund_goal: item.fund_goal,
        fund_balance: item.rollover? ? (item.fund_balance || 0) + (item.planned_amount || 0) - (item.spent_amount || 0) : 0
      )
    end
  end

  def recalculate_totals!
    update!(
      total_income: incomes.sum(:received_amount),
      total_planned: budget_items.sum(:planned_amount),
      total_spent: budget_items.sum(:spent_amount)
    )
  end
end
