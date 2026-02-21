class CreateRecurringBills < ActiveRecord::Migration[8.0]
  def change
    create_table :recurring_bills do |t|
      t.string :name, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.references :account, null: true, foreign_key: true
      t.references :budget_category, null: true, foreign_key: true
      t.integer :due_day, null: false
      t.integer :frequency
      t.boolean :auto_create_transaction, default: false
      t.integer :reminder_days_before
      t.boolean :active, default: true
      t.date :last_paid_date
      t.date :next_due_date

      t.timestamps
    end
  end
end
