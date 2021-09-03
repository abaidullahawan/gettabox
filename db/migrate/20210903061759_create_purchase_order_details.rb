class CreatePurchaseOrderDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :purchase_order_details do |t|
      t.references :purchase_order
      t.references :product
      t.decimal :cost_price
      t.integer :quantity

      t.timestamps
    end
  end
end
