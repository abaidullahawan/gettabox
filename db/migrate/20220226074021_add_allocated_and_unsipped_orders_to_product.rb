class AddAllocatedAndUnsippedOrdersToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :allocated, :decimal
    add_column :products, :unshipped_orders, :integer
  end
end
