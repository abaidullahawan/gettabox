class AddOrderTypeToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :order_type, :string
  end
end
