class AddPaymentMethodToPurchaseOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_orders, :payment_method, :integer
  end
end
