class CreateAttributeSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :attribute_settings do |t|
      t.string :model
      t.belongs_to :user, null: false, foreign_key: true
      t.integer :type
      t.json :table_attributes

      t.timestamps
    end
  end
end
