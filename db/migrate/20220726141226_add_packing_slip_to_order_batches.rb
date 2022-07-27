class AddPackingSlipToOrderBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :packing_slip, :boolean
  end
end
