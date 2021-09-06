class AddProductQuantityToMultipackProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :multipack_products, :quantity, :decimal
  end
end
