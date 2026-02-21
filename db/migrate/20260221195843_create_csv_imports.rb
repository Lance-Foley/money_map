class CreateCsvImports < ActiveRecord::Migration[8.0]
  def change
    create_table :csv_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.string :file_name
      t.integer :status, default: 0
      t.json :column_mapping
      t.integer :records_imported, default: 0
      t.integer :records_skipped, default: 0
      t.text :error_log

      t.timestamps
    end
  end
end
