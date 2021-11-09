class AddColumnsToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :address, :string
    add_column :channel_orders, :total_amount, :string
    add_column :channel_orders, :buyer_name, :string
  end
end
