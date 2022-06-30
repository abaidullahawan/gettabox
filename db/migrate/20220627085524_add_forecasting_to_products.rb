class AddForecastingToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :forecasting, :jsonb
  end
end
