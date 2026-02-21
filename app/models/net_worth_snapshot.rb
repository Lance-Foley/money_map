class NetWorthSnapshot < ApplicationRecord
  validates :recorded_at, presence: true, uniqueness: true
  validates :net_worth, presence: true

  scope :chronological, -> { order(:recorded_at) }
  scope :recent, ->(count = 12) { chronological.last(count) }

  def self.capture!
    assets = Account.active.assets.sum(:balance)
    liabilities = Account.active.debts.sum(:balance)

    breakdown = Account.active.map { |a|
      { id: a.id, name: a.name, type: a.account_type, balance: a.balance.to_f }
    }

    create!(
      recorded_at: Date.current,
      total_assets: assets,
      total_liabilities: liabilities,
      net_worth: assets - liabilities,
      breakdown: breakdown
    )
  end
end
