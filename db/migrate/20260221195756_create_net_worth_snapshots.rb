class CreateNetWorthSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :net_worth_snapshots do |t|
      t.date :recorded_at, null: false
      t.decimal :total_assets, precision: 12, scale: 2
      t.decimal :total_liabilities, precision: 12, scale: 2
      t.decimal :net_worth, precision: 12, scale: 2, null: false
      t.json :breakdown

      t.timestamps
    end

    add_index :net_worth_snapshots, :recorded_at, unique: true
  end
end
