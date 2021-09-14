class AddMissingAndDemagedToPurchaseDeliveryDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_delivery_details, :missing, :integer
    add_column :purchase_delivery_details, :demaged, :integer
  end
end
