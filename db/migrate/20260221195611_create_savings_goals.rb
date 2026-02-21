class CreateSavingsGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :savings_goals do |t|
      t.string :name, null: false
      t.decimal :target_amount, precision: 12, scale: 2, null: false
      t.decimal :current_amount, precision: 12, scale: 2, default: 0.0
      t.date :target_date
      t.integer :category
      t.integer :priority

      t.timestamps
    end
  end
end
