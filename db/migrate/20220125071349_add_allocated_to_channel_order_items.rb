class AddAllocatedToChannelOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_order_items, :allocated, :boolean
  end
end
