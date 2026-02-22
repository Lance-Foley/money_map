class Account < ApplicationRecord
  enum :account_type, {
    checking: 0, savings: 1, credit_card: 2,
    loan: 3, mortgage: 4, investment: 5
  }

  has_many :transactions, dependent: :nullify
  has_many :debt_payments, dependent: :destroy
  has_many :recurring_transactions, dependent: :nullify
  has_many :csv_imports, dependent: :destroy

  validates :name, presence: true
  validates :account_type, presence: true
  validates :balance, numericality: true
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minimum_payment, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(account_type: type) }
  scope :debts, -> { where(account_type: [:credit_card, :loan, :mortgage]) }
  scope :assets, -> { where(account_type: [:checking, :savings, :investment]) }

  def debt?
    credit_card? || loan? || mortgage?
  end

  def asset?
    checking? || savings? || investment?
  end
end
