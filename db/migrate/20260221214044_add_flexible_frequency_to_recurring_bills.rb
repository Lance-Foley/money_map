class AddFlexibleFrequencyToRecurringBills < ActiveRecord::Migration[8.0]
  def up
    add_column :recurring_bills, :start_date, :date
    add_column :recurring_bills, :custom_interval_value, :integer
    add_column :recurring_bills, :custom_interval_unit, :integer

    # Migrate existing frequency values:
    # old: monthly: 0, quarterly: 1, annual: 2
    # new: weekly: 0, biweekly: 1, semimonthly: 2, monthly: 3, quarterly: 4, semi_annual: 5, annual: 6, custom: 7
    execute <<-SQL
      UPDATE recurring_bills SET frequency = CASE frequency
        WHEN 0 THEN 3
        WHEN 1 THEN 4
        WHEN 2 THEN 6
        ELSE frequency
      END
    SQL

    # Set start_date from due_day for existing records
    execute <<-SQL
      UPDATE recurring_bills
      SET start_date = date('2026-01-01', '+' || (due_day - 1) || ' days')
      WHERE start_date IS NULL
    SQL
  end

  def down
    # Reverse the frequency mapping
    execute <<-SQL
      UPDATE recurring_bills SET frequency = CASE frequency
        WHEN 3 THEN 0
        WHEN 4 THEN 1
        WHEN 6 THEN 2
        ELSE 0
      END
    SQL

    remove_column :recurring_bills, :start_date
    remove_column :recurring_bills, :custom_interval_value
    remove_column :recurring_bills, :custom_interval_unit
  end
end
