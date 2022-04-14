class AddColumnTotalWeightChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :total_weight, :float
  end
end
