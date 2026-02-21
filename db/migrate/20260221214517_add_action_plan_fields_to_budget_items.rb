class AddActionPlanFieldsToBudgetItems < ActiveRecord::Migration[8.0]
  def change
    add_column :budget_items, :expected_date, :date
    add_column :budget_items, :recurring_bill_id, :integer
    add_column :budget_items, :auto_generated, :boolean, default: false

    add_index :budget_items, :recurring_bill_id
    add_index :budget_items, :expected_date
    add_foreign_key :budget_items, :recurring_bills
  end
end
