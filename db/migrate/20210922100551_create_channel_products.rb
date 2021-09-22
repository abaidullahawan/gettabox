class CreateChannelProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_products do |t|
      t.integer :channel_type
      t.jsonb :product_data

      t.timestamps
    end
  end
end
