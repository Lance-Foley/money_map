class BudgetItem < ApplicationRecord
  belongs_to :budget_period
  belongs_to :budget_category
  belongs_to :recurring_bill, optional: true
  has_many :transactions, dependent: :nullify
  has_many :transaction_splits, dependent: :destroy

  validates :name, presence: true
  validates :planned_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :by_category, ->(cat) { where(budget_category: cat) }
  scope :chronological, -> { order(:expected_date) }
  scope :for_recurring_bill, ->(bill) { where(recurring_bill: bill) }

  def remaining
    (planned_amount || 0) - (spent_amount || 0)
  end

  def over_budget?
    remaining.negative?
  end

  def percentage_spent
    return 0.0 if planned_amount.nil? || planned_amount.zero?
    ((spent_amount || 0).to_f / planned_amount * 100).round(1)
  end

  def sinking_fund?
    rollover?
  end

  def from_recurring?
    recurring_bill_id.present?
  end

  def recalculate_spent!
    total = transactions.sum(:amount) + transaction_splits.sum(:amount)
    update!(spent_amount: total)
    budget_period.recalculate_totals!
  end
end
