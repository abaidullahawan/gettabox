class ChangeItemIdInChannelProducts < ActiveRecord::Migration[6.1]
  def change
    change_column :channel_products, :item_id, :bigint
  end
end
