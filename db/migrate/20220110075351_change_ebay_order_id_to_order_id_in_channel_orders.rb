class ChangeEbayOrderIdToOrderIdInChannelOrders < ActiveRecord::Migration[6.1]
  def change
    rename_column :channel_orders, :ebayorder_id, :order_id
  end
end
