class AddOrderStatusToPurchaseOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_orders, :order_status, :integer
  end
end
