class AddPalletQuantitToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :pallet_quantity, :integer
    change_column :products, :pack_quantity, 'integer USING CAST(pack_quantity AS integer)'
  end
end
