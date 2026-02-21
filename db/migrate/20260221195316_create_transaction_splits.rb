class CreateTransactionSplits < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_splits do |t|
      t.references :transaction_record, null: false, foreign_key: { to_table: :transactions }
      t.references :budget_item, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
