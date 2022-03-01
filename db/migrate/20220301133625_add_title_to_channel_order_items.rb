class AddTitleToChannelOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_order_items, :title, :string
  end
end
