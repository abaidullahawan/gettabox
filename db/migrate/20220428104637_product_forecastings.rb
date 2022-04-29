class ProductForecastings < ActiveRecord::Migration[6.1]
  def change
    create_table :product_forecastings do |t|
      t.references :product
      t.references :channel_forecasting
    end
  end
end
