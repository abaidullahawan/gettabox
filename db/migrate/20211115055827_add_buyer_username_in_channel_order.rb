class AddBuyerUsernameInChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :buyer_username, :string
  end
end
