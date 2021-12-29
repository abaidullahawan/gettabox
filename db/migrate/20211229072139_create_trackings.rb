class CreateTrackings < ActiveRecord::Migration[6.1]
  def change
    create_table :trackings do |t|
      t.string :tracking_no
      t.string :ebayorder_id
      t.references :channel_order, null: true

      t.timestamps
    end
  end
end
