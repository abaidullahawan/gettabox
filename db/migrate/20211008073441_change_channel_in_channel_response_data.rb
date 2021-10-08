class ChangeChannelInChannelResponseData < ActiveRecord::Migration[6.1]
  def change
    change_column :channel_response_data, :channel, 'integer USING CAST(channel AS integer)'
  end
end
