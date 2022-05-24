class AddItemQuantityChangedToChannelProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :item_quantity_changed, :boolean
  end
end
