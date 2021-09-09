class AddVatToPurchaseOrderDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_order_details, :vat, :decimal
  end
end
