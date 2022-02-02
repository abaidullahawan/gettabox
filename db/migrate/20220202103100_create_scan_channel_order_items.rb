class CreateScanChannelOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :product_scan, :jsonb
  end
end
