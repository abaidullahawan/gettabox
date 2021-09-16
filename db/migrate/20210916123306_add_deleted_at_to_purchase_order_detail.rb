class AddDeletedAtToPurchaseOrderDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_order_details, :deleted_at, :datetime
    add_index :purchase_order_details, :deleted_at
  end
end
