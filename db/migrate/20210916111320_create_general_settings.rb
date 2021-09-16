class CreateGeneralSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :general_settings do |t|
      t.string :name
      t.string :display_name
      t.string :phone
      t.string :address

      t.timestamps
    end
  end
end
