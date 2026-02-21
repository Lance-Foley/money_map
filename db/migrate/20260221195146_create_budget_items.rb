class CreateBudgetItems < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_items do |t|
      t.references :budget_period, null: false, foreign_key: true
      t.references :budget_category, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :planned_amount, precision: 12, scale: 2, default: 0.0
      t.decimal :spent_amount, precision: 12, scale: 2, default: 0.0
      t.boolean :rollover, default: false
      t.decimal :fund_goal, precision: 12, scale: 2, default: 0.0
      t.decimal :fund_balance, precision: 12, scale: 2, default: 0.0

      t.timestamps
    end
  end
end
