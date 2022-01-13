class AddReferenceOrderbatchToChannelorder < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_orders, :order_batch
  end
end
