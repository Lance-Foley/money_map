class BudgetCategory < ApplicationRecord
  has_many :budget_items, dependent: :destroy
  has_many :recurring_transactions, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(:position) }
end
