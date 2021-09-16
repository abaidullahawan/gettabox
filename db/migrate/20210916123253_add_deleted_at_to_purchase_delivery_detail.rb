class AddDeletedAtToPurchaseDeliveryDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_delivery_details, :deleted_at, :datetime
    add_index :purchase_delivery_details, :deleted_at
  end
end
