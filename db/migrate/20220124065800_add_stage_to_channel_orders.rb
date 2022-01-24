class AddStageToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :stage, :string
  end
end
