class CreateChannelOrderItems < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_order_items do |t|
      t.string :sku
      t.json :item_data
      t.references :channel_order
      t.timestamps
    end
  end
end
