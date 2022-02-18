class RemoveProductsFromProductLocation < ActiveRecord::Migration[6.1]
  def change
    remove_reference :product_locations, :product
  end
end
