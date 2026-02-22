class Income < ApplicationRecord
  belongs_to :budget_period
  belongs_to :recurring_transaction, optional: true

  validates :source_name, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than: 0 }

  scope :recurring_sources, -> { where(recurring: true, auto_generated: false) }

  after_save :recalculate_period_income
  after_destroy :recalculate_period_income

  def received?
    received_amount.present? && received_amount > 0
  end

  private

  def recalculate_period_income
    budget_period.recalculate_totals!
  end
end
