class ChannelTypeInSystemUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :system_users, :sales_channel, :string
  end
end
