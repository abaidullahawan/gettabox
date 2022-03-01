class AddUpdateChannelToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :update_channel, :boolean, default: false
  end
end
