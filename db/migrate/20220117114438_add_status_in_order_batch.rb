class AddStatusInOrderBatch < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :status, :string
  end
end
