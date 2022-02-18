class RenameItemIdToListingIdInChannelProducts < ActiveRecord::Migration[6.1]
  def change
    rename_column :channel_products, :item_id, :listing_id
  end
end
