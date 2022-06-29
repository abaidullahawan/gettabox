class AddQuantityTypeToPurchaseOrderDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_order_details, :quantity_type, :integer, default: 0
    add_column :purchase_order_details, :total, :decimal, default: 0
  end
end
