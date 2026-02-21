class AddFlexibleFrequencyToIncomes < ActiveRecord::Migration[8.0]
  def up
    add_column :incomes, :start_date, :date
    add_column :incomes, :custom_interval_value, :integer
    add_column :incomes, :custom_interval_unit, :integer
    add_column :incomes, :auto_generated, :boolean, default: false
    add_column :incomes, :recurring_source_id, :integer

    add_index :incomes, :recurring_source_id

    # Migrate existing frequency values:
    # old: one_time: 0, weekly: 1, biweekly: 2, semimonthly: 3, monthly: 4
    # new: weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3, quarterly: 4, semi_annual: 5, annual: 6, custom: 7

    # Step 1: Handle one_time (0) -> set recurring to false, frequency to monthly (3) as default
    execute <<-SQL
      UPDATE incomes SET
        recurring = 0,
        frequency = 3
      WHERE frequency = 0
    SQL

    # Step 2: Remap in reverse order to avoid collisions
    # monthly (4) -> 3
    execute "UPDATE incomes SET frequency = 3 WHERE frequency = 4"
    # semimonthly (3) -> 2 (only recurring to avoid double-updating one_time records)
    execute "UPDATE incomes SET frequency = 2 WHERE frequency = 3 AND recurring = 1"
    # biweekly (2) -> 1 (only recurring)
    execute "UPDATE incomes SET frequency = 1 WHERE frequency = 2 AND recurring = 1"
    # weekly (1) -> 0 (only recurring)
    execute "UPDATE incomes SET frequency = 0 WHERE frequency = 1 AND recurring = 1"

    # Set start_date from pay_date for existing records
    execute <<-SQL
      UPDATE incomes SET start_date = pay_date WHERE start_date IS NULL AND pay_date IS NOT NULL
    SQL
  end

  def down
    remove_index :incomes, :recurring_source_id
    remove_column :incomes, :start_date
    remove_column :incomes, :custom_interval_value
    remove_column :incomes, :custom_interval_unit
    remove_column :incomes, :auto_generated
    remove_column :incomes, :recurring_source_id
  end
end
