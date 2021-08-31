class CreateTableMultipackProduct < ActiveRecord::Migration[6.1]
  def change
    create_table :multipack_products do |t|
      t.belongs_to :product
      t.belongs_to :child

      t.timestamps
    end
  end
end
