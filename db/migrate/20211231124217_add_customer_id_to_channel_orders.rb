class AddCustomerIdToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_orders, :system_user
  end
end
