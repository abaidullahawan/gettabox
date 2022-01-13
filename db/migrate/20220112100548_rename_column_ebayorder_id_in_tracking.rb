class RenameColumnEbayorderIdInTracking < ActiveRecord::Migration[6.1]
  def change
    rename_column :trackings, :ebayorder_id, :order_id
  end
end
