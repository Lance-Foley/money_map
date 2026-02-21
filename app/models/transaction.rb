class Transaction < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :budget_item, optional: true
  has_many :transaction_splits, foreign_key: :transaction_record_id, dependent: :destroy

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }

  validates :amount, presence: true, numericality: true
  validates :date, presence: true
  validates :transaction_type, presence: true

  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :uncategorized, -> { where(budget_item_id: nil) }
  scope :chronological, -> { order(date: :desc, created_at: :desc) }
  scope :imported, -> { where(imported: true) }

  after_save :recalculate_budget_item
  after_destroy :recalculate_budget_item

  def split?
    transaction_splits.any?
  end

  private

  def recalculate_budget_item
    budget_item&.recalculate_spent!
  end
end
