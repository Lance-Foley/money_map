class CreateBudgetCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_categories do |t|
      t.string :name, null: false
      t.integer :position, null: false
      t.string :icon
      t.string :color

      t.timestamps
    end

    add_index :budget_categories, :name, unique: true
  end
end
