class AddSelectedToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :selected, :boolean
  end
end
