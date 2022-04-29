class AddBufferQuantityToChannelProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :buffer_quantity, :string
  end
end
