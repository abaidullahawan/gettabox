class AddReferenceForecastingsToProduct < ActiveRecord::Migration[6.1]
  def change
    add_reference :products, :channel_forecasting
  end
end
