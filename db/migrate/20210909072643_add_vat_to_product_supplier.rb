class AddVatToProductSupplier < ActiveRecord::Migration[6.1]
  def change
    add_column :product_suppliers, :product_vat, :decimal
  end
end
