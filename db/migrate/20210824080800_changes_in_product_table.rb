class ChangesInProductTable < ActiveRecord::Migration[6.1]
  def change
    execute 'DROP TABLE products CASCADE'

    create_table :products do |t|
      t.string :sku, unique: true
      t.string :title
      t.decimal :total_stock
      t.decimal :fake_stock
      t.decimal :pending_orders
      t.decimal :allocated_orders
      t.decimal :available_stock
      t.belongs_to :category, null: true, foreign_key: true
      t.decimal :length
      t.decimal :width
      t.decimal :height
      t.decimal :weight
      t.string :pack_quantity
      t.decimal :cost_price
      t.decimal :gst
      t.decimal :vat
      t.decimal :hst
      t.decimal :pst
      t.decimal :qst
      t.decimal :minimum
      t.decimal :maximum
      t.decimal :optimal

      t.timestamps
    end
  end
end
