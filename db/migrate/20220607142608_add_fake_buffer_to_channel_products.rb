class AddFakeBufferToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :fake_buffer, :boolean
    add_column :channel_products, :channel_quantity, :integer
  end
end
