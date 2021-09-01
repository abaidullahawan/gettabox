class ChangeColumnSytemUserIdNullTrueInProductSupplier < ActiveRecord::Migration[6.1]
  def up
    change_column :product_suppliers, :system_user_id, :bigint, null: true
    change_column :product_suppliers, :product_id, :bigint, null: true

  end

  def down
    change_column :product_suppliers, :system_user_id, :bigint, null: false
    change_column :product_suppliers, :product_id, :bigint, null: false
  end
end
