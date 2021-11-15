class AddChannelProductIdInChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :channel_order_id, :integer
  end
end
