class CreateChannelResponseData < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_response_data do |t|
      t.string :channel
      t.jsonb :response
      t.string :api_call
      t.string :api_url
      t.timestamps
    end
  end
end
