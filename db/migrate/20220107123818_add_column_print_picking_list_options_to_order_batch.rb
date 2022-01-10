class AddColumnPrintPickingListOptionsToOrderBatch < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :print_packing_list_option, :string
    change_column :order_batches, :print_packing_list, 'boolean USING CAST(print_packing_list AS boolean)'
  end
end
