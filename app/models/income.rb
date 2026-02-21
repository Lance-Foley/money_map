class Income < ApplicationRecord
  include Schedulable

  belongs_to :budget_period

  enum :frequency, {
    weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3,
    quarterly: 4, semi_annual: 5, annual: 6, custom: 7
  }

  validates :source_name, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than: 0 }
  validates :custom_interval_value, presence: true, numericality: { greater_than: 0 }, if: :custom?
  validates :custom_interval_unit, presence: true, if: :custom?

  scope :recurring_sources, -> { where(recurring: true, auto_generated: false) }

  after_save :recalculate_period_income
  after_destroy :recalculate_period_income

  def received?
    received_amount.present? && received_amount > 0
  end

  private

  # Override Schedulable's frequency_name to work with ActiveRecord enum
  # (enum returns a string like "monthly", not an integer)
  def frequency_name
    frequency&.to_sym
  end

  def recalculate_period_income
    budget_period.recalculate_totals!
  end
end
