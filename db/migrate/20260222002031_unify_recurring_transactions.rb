class UnifyRecurringTransactions < ActiveRecord::Migration[8.0]
  def up
    # 1. Rename recurring_bills -> recurring_transactions
    rename_table :recurring_bills, :recurring_transactions

    # 2. Add direction column (0=income, 1=expense, 2=transfer)
    add_column :recurring_transactions, :direction, :integer, default: 1, null: false

    # 3. Rename foreign key in budget_items
    rename_column :budget_items, :recurring_bill_id, :recurring_transaction_id

    # 4. Add recurring_transaction_id to incomes
    add_column :incomes, :recurring_transaction_id, :integer
    add_index :incomes, :recurring_transaction_id

    # 5. Data migration: convert recurring Income sources into RecurringTransaction records
    execute <<~SQL
      INSERT INTO recurring_transactions (name, amount, due_day, frequency, start_date, custom_interval_value, custom_interval_unit, active, direction, created_at, updated_at)
      SELECT source_name, expected_amount, CAST(strftime('%d', pay_date) AS INTEGER), frequency, start_date, custom_interval_value, custom_interval_unit, 1, 0, datetime('now'), datetime('now')
      FROM incomes
      WHERE recurring = 1 AND auto_generated = 0
      GROUP BY source_name
    SQL

    # 6. Link income entries to their new RecurringTransaction
    execute <<~SQL
      UPDATE incomes
      SET recurring_transaction_id = (
        SELECT rt.id FROM recurring_transactions rt
        WHERE rt.name = incomes.source_name AND rt.direction = 0
        LIMIT 1
      )
      WHERE recurring = 1
      AND EXISTS (
        SELECT 1 FROM recurring_transactions rt
        WHERE rt.name = incomes.source_name AND rt.direction = 0
      )
    SQL
  end

  def down
    remove_column :incomes, :recurring_transaction_id
    rename_column :budget_items, :recurring_transaction_id, :recurring_bill_id
    remove_column :recurring_transactions, :direction
    rename_table :recurring_transactions, :recurring_bills
  end
end
