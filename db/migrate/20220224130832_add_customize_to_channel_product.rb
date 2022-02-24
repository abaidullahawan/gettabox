class AddCustomizeToChannelProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :customize, :boolean
  end
end
