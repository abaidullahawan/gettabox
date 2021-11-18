class AddColumnToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :item_quantity, :decimal
  end
end
