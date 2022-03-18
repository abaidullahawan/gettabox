class ChangeColumnTypeOfChannelOrders < ActiveRecord::Migration[6.1]
  def change
    change_column :channel_orders, :total_amount, 'float USING total_amount::float'
  end
end
