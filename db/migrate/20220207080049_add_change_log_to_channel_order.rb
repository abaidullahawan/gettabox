class AddChangeLogToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :change_log, :string
  end
end
