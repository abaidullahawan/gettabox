class CreateProductLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :product_locations do |t|
      t.string :location
      t.references :product
      t.timestamps
    end
  end
end
