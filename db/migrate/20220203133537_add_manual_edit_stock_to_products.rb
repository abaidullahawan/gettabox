class AddManualEditStockToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :manual_edit_stock, :integer
  end
end
