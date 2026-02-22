class AddAnalysisResultsToCsvImports < ActiveRecord::Migration[8.0]
  def change
    add_column :csv_imports, :analysis_results, :json
    change_column_null :csv_imports, :account_id, true
  end
end
