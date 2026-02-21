class CreateDebtPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :debt_payments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :budget_period, null: true, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :payment_date, null: false
      t.decimal :principal_portion, precision: 12, scale: 2
      t.decimal :interest_portion, precision: 12, scale: 2

      t.timestamps
    end
  end
end
