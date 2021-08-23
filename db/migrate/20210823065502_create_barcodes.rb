class CreateBarcodes < ActiveRecord::Migration[6.1]
  def change
    create_table :barcodes do |t|
      t.string :title
      t.belongs_to :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
