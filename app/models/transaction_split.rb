class TransactionSplit < ApplicationRecord
  belongs_to :transaction_record, class_name: "Transaction"
  belongs_to :budget_item

  validates :amount, presence: true, numericality: { greater_than: 0 }

  after_save :recalculate_budget_item
  after_destroy :recalculate_budget_item

  private

  def recalculate_budget_item
    budget_item.recalculate_spent!
  end
end
