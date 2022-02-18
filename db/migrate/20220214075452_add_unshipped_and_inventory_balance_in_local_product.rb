class AddUnshippedAndInventoryBalanceInLocalProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :unshipped, :integer
    add_column :products, :inventory_balance, :integer
    add_column :products, :unallocated, :integer
  end
end
