class AddSelectedToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :selected, :boolean
  end
end
