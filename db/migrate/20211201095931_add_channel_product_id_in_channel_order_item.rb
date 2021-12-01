class AddChannelProductIdInChannelOrderItem < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_order_items, :channel_product
  end
end
