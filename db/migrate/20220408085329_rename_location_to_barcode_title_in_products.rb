class RenameLocationToBarcodeTitleInProducts < ActiveRecord::Migration[6.1]
  def change
    rename_column :products, :location, :barcode
  end
end
