class DebtPayment < ApplicationRecord
  belongs_to :account
  belongs_to :budget_period, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true

  scope :for_account, ->(account) { where(account: account) }
  scope :chronological, -> { order(:payment_date) }
end
