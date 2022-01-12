class AddProductReferenceInChannelOrderItem < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_order_items, :product, null: true
  end
end
