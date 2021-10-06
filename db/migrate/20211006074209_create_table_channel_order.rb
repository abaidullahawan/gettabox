class CreateTableChannelOrder < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_orders do |t|
      t.integer :channel_type
      t.jsonb :order_data
      t.timestamps
    end
  end
end
