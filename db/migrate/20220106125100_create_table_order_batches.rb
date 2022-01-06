class CreateTableOrderBatches < ActiveRecord::Migration[6.1]
  def change
    create_table :order_batches do |t|
      t.string :pick_preset
      t.string :print_packing_list
      t.boolean :orders
      t.boolean :products
      t.boolean :mark_as_picked
      t.boolean :print_courier_labels
      t.date :print_date
      t.boolean :print_invoice
      t.boolean :update_channels
      t.boolean :mark_order_as_dispatched
      t.string :batch_name
      t.boolean :shipping_rule_max_weight
      t.boolean :overwrite_order_notes
      t.string :options

      t.timestamps
    end
  end
end
