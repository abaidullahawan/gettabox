class AddInvoiceNumberToPurchaseOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_orders, :invoice_number, :integer
  end
end
