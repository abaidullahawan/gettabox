class RemoveSkuFromSystemUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :system_users, :sku
  end
end
