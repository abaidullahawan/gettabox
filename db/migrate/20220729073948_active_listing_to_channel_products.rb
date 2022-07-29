class ActiveListingToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :active_listing, :boolean, default: 1
  end
end
