class CreateRefreshTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :refresh_tokens do |t|
      t.string :channel
      t.string :refresh_token
      t.datetime :refresh_token_expiry
      t.string :access_token
      t.datetime :access_token_expiry

      t.timestamps
    end
  end
end
