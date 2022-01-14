class AddDeletedAtToOrderBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :deleted_at, :datetime
    add_index :order_batches, :deleted_at
  end
end
