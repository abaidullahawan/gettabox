class AddDeletedAtToPurchaseDelivery < ActiveRecord::Migration[6.1]
  def change
    add_column :purchase_deliveries, :deleted_at, :datetime
    add_index :purchase_deliveries, :deleted_at
  end
end
