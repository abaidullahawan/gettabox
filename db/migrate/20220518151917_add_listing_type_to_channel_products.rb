class AddListingTypeToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :listing_type, :string
  end
end
