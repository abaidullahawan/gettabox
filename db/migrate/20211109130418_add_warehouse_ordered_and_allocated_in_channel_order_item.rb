class AddWarehouseOrderedAndAllocatedInChannelOrderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_order_items, :warehouse, :integer
    add_column :channel_order_items, :ordered, :integer
    add_column :channel_order_items, :allocated, :integer
  end
end
