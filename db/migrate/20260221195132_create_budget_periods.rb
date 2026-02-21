class CreateBudgetPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_periods do |t|
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :status, default: 0
      t.decimal :total_income, precision: 12, scale: 2, default: 0.0
      t.decimal :total_planned, precision: 12, scale: 2, default: 0.0
      t.decimal :total_spent, precision: 12, scale: 2, default: 0.0

      t.timestamps
    end

    add_index :budget_periods, [:year, :month], unique: true
  end
end
