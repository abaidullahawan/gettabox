class AddReadyToPrintInChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :ready_to_print, :boolean
  end
end
