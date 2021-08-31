class AddProductCostAndProductSkuToProductSuppliers < ActiveRecord::Migration[6.1]
  def change
    add_column :product_suppliers, :product_cost, :decimal
    add_column :product_suppliers, :product_sku, :string
  end
end
