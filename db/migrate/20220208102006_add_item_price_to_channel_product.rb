class AddItemPriceToChannelProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :item_price, :string
  end
end
