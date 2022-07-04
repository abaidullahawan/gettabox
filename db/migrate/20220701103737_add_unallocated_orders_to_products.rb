class AddUnallocatedOrdersToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :ebay_unallocated_orders, :integer, default: 0
    add_column :products, :amazon_unallocated_orders, :integer, default: 0
  end
end
