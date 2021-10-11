class AddEbayorderIdToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :ebayorder_id, :string
  end
end
