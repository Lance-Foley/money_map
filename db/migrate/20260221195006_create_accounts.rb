class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false
      t.string :institution_name
      t.decimal :balance, precision: 12, scale: 2, default: 0.0
      t.decimal :interest_rate, precision: 5, scale: 4
      t.decimal :minimum_payment, precision: 10, scale: 2
      t.decimal :credit_limit, precision: 12, scale: 2
      t.decimal :original_balance, precision: 12, scale: 2
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
