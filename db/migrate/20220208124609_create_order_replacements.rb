class CreateOrderReplacements < ActiveRecord::Migration[6.1]
  def change
    create_table :order_replacements do |t|
      t.references :channel_order
      t.references :order_replacement
      t.string :order_id
      t.timestamps
    end
  end
end
