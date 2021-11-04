class AddOrderStatusInChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :order_status, :string
    add_column :channel_orders, :payment_status, :string
  end
end
