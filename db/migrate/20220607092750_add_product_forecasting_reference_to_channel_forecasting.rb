class AddProductForecastingReferenceToChannelForecasting < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_forecastings, :product_forecasting
    remove_reference :channel_forecastings, :system_user
    remove_column :channel_forecastings, :comparison_number, :string
  end
end
