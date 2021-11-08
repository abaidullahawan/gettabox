class AddLineItemIdInChannelOrderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_order_items, :line_item_id, :string
  end
end
