class CreatePurchaseDeliveryDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :purchase_delivery_details do |t|
      t.belongs_to :purchase_delivery, null: false, foreign_key: true
      t.belongs_to :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :cost_price

      t.timestamps
    end
  end
end
