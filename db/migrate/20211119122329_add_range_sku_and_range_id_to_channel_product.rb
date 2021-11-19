class AddRangeSkuAndRangeIdToChannelProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :product_range_id, :string
    add_column :channel_products, :range_sku, :string
  end
end
