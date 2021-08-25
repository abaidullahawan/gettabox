class CreateSuppliers < ActiveRecord::Migration[6.1]
  def change
    create_table :product_suppliers do |t|
      t.belongs_to :product, null: false, foreign_key: true
      t.belongs_to :system_user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
