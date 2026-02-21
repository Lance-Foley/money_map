class Income < ApplicationRecord
  belongs_to :budget_period

  enum :frequency, { one_time: 0, weekly: 1, biweekly: 2, semimonthly: 3, monthly: 4 }

  validates :source_name, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than: 0 }

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
