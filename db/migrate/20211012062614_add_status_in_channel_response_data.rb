class AddStatusInChannelResponseData < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_response_data, :status, :string
  end
end
