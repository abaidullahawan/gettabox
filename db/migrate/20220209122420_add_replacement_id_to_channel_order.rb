class AddReplacementIdToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :replacement_id, :string
  end
end
