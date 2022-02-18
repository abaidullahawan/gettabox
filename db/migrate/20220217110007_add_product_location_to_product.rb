class AddProductLocationToProduct < ActiveRecord::Migration[6.1]
  def change
    add_reference :products, :product_location, foreign_key: true
  end
end
