class ChangeTypeOfWarehouseInChannelOrderItem < ActiveRecord::Migration[6.1]
  def change
    remove_column :channel_order_items, :warehouse, :integer
    remove_column :channel_order_items, :allocated, :integer
  end
end
