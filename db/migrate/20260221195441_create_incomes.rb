class CreateIncomes < ActiveRecord::Migration[8.0]
  def change
    create_table :incomes do |t|
      t.references :budget_period, null: false, foreign_key: true
      t.string :source_name, null: false
      t.decimal :expected_amount, precision: 12, scale: 2
      t.decimal :received_amount, precision: 12, scale: 2
      t.date :pay_date
      t.boolean :recurring, default: false
      t.integer :frequency

      t.timestamps
    end
  end
end
