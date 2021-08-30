class AddProductTypeToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :product_type, :integer
  end
end
