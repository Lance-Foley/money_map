class RecurringBill < ApplicationRecord
  include Schedulable

  belongs_to :account, optional: true
  belongs_to :budget_category, optional: true

  enum :frequency, {
    weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3,
    quarterly: 4, semi_annual: 5, annual: 6, custom: 7
  }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_day, presence: true, inclusion: { in: 1..31 }
  validates :start_date, presence: true
  validates :custom_interval_value, presence: true, numericality: { greater_than: 0 }, if: :custom?
  validates :custom_interval_unit, presence: true, if: :custom?

  scope :active, -> { where(active: true) }
  scope :due_soon, ->(days = 7) {
    today = Date.current
    active.where("next_due_date <= ?", today + days.days).where("next_due_date >= ?", today)
  }

  before_validation :default_frequency, if: -> { frequency.blank? }
  before_validation :set_start_date_from_due_day, if: -> { start_date.blank? && due_day.present? }
  before_save :calculate_next_due_date

  def days_until_due
    return nil unless next_due_date
    (next_due_date - Date.current).to_i
  end

  def overdue?
    next_due_date.present? && next_due_date < Date.current
  end

  private

  # Override Schedulable's frequency_name to work with ActiveRecord enum
  # (enum returns a string like "monthly", not an integer)
  def frequency_name
    frequency&.to_sym
  end

  def default_frequency
    self.frequency = :monthly
  end

  def set_start_date_from_due_day
    return unless (1..31).cover?(due_day)
    today = Date.current
    day = [due_day, Date.new(today.year, today.month, -1).day].min
    self.start_date = Date.new(today.year, today.month, day)
  end

  def calculate_next_due_date
    return unless start_date.present?
    self.next_due_date = next_occurrence_after(Date.current - 1.day)
  end
end
