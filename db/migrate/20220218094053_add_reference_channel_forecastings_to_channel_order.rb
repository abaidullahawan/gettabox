class AddReferenceChannelForecastingsToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_products, :channel_forecasting
  end
end
