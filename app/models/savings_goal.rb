class SavingsGoal < ApplicationRecord
  enum :category, { emergency_fund: 0, sinking_fund: 1, general: 2 }

  validates :name, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where("current_amount < target_amount") }
  scope :completed, -> { where("current_amount >= target_amount") }
  scope :by_priority, -> { order(:priority) }

  def progress_percentage
    return 0.0 if target_amount.nil? || target_amount.zero?
    [(current_amount.to_f / target_amount * 100).round(1), 100.0].min
  end

  def completed?
    (current_amount || 0) >= target_amount
  end

  def remaining
    [target_amount - (current_amount || 0), 0].max
  end

  def months_to_goal(monthly_contribution)
    return nil if monthly_contribution.nil? || monthly_contribution.zero?
    (remaining / monthly_contribution).ceil
  end
end
