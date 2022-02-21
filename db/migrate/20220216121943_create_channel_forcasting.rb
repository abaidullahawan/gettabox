class CreateChannelForcasting < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_forecastings do |t|
      t.integer :filter_name
      t.string :filter_by
      t.integer :action
      t.integer :type_number
      t.integer :units
      t.string :name
      t.string :comparison_number
      t.references :system_user

      t.timestamps
    end
  end
end
