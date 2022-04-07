class AddMarkAsBatchNameToOrderBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :mark_as_batch_name, :boolean
  end
end
