class RecurringBill < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :budget_category, optional: true

  enum :frequency, { monthly: 0, quarterly: 1, annual: 2 }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_day, presence: true, inclusion: { in: 1..31 }

  scope :active, -> { where(active: true) }
  scope :due_soon, ->(days = 7) {
    today = Date.current
    active.where("next_due_date <= ?", today + days.days).where("next_due_date >= ?", today)
  }

  before_save :calculate_next_due_date

  def days_until_due
    return nil unless next_due_date
    (next_due_date - Date.current).to_i
  end

  def overdue?
    next_due_date.present? && next_due_date < Date.current
  end

  private

  def calculate_next_due_date
    return if next_due_date.present? && !due_day_changed?
    today = Date.current
    day = [due_day, Date.new(today.year, today.month, -1).day].min
    candidate = Date.new(today.year, today.month, day)
    self.next_due_date = candidate >= today ? candidate : candidate.next_month
  end
end
