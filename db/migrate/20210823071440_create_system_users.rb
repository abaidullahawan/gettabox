class CreateSystemUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :system_users do |t|
      t.string :sku
      t.integer :user_type
      t.belongs_to :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
