class RemoveAddressFromChannelOrder < ActiveRecord::Migration[6.1]
  def change
    remove_column :channel_orders, :address
  end
end
