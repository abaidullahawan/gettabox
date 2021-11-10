class AddLocationInProductTableAndChangeTypeOfItemIdInChannelProduct < ActiveRecord::Migration[6.1]
  def change
    change_column :channel_products, :item_id, :string
    add_column :products, :location, :string
  end
end
