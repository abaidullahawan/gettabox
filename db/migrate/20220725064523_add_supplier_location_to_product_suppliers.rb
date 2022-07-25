class AddSupplierLocationToProductSuppliers < ActiveRecord::Migration[6.1]
  def change
    add_column :product_suppliers, :supplier_location, :string
  end
end
