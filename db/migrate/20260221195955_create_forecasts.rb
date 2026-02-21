class CreateForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :forecasts do |t|
      t.string :name, null: false
      t.json :assumptions
      t.integer :projection_months, null: false
      t.json :results

      t.timestamps
    end
  end
end
