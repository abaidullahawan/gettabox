class AddDeletedAtToPurchaseOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_orders, :deleted_at, :datetime
    add_index :purchase_orders, :deleted_at
  end
end
