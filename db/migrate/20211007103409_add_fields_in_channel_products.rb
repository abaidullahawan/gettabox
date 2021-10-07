class AddFieldsInChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :item_id, :integer
    add_column :channel_products, :item_sku, :string
  end
end
