class AddAccountToBudgetItems < ActiveRecord::Migration[8.0]
  def change
    add_column :budget_items, :account_id, :integer
    add_index :budget_items, :account_id
  end
end
