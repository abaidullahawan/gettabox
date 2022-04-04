class AddColumnPostageToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :postage, :string
  end
end
