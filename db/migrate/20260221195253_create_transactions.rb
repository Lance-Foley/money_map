class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :account, null: true, foreign_key: true
      t.references :budget_item, null: true, foreign_key: true
      t.date :date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :description
      t.string :merchant
      t.text :notes
      t.integer :transaction_type, null: false
      t.boolean :imported, default: false

      t.timestamps
    end

    add_index :transactions, :date
    add_index :transactions, :transaction_type
  end
end
