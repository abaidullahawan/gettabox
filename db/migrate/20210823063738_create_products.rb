class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :title
      t.string :sku
      t.integer :location
      t.string :dimensions
      t.string :weight
      t.integer :pack_quantity
      t.string :cost
      t.integer :stock_alert
      t.string :sold
      t.integer :total
      t.integer :fake_stock
      t.integer :pending_orders
      t.integer :allocated
      t.integer :available

      t.timestamps
    end
  end
end
