class AddColumnsToChannelProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :item_name, :string
    add_column :channel_products, :item_image, :string
    add_column :channel_products, :error_message, :string
  end
end
