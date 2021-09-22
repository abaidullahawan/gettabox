class CreateProductMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :product_mappings do |t|
      t.references :channel_product
      t.references :product

      t.timestamps
    end
  end
end
