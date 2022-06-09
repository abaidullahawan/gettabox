class AddNameToProductForecastings < ActiveRecord::Migration[6.1]
  def change
    add_column :product_forecastings, :name, :string
    remove_reference :product_forecastings, :channel_forecasting
    remove_reference :product_forecastings, :product
    add_column :product_forecastings, :created_at, :datetime, null: false, default: DateTime.now
    add_column :product_forecastings, :updated_at, :datetime, null: false, default: DateTime.now
  end
end
