class AddMissingAndDemagedToPurchaseOrderDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_order_details, :missing, :integer
    add_column :purchase_order_details, :demaged, :integer
  end
end
