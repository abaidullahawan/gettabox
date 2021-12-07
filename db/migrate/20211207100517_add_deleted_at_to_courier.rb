class AddDeletedAtToCourier < ActiveRecord::Migration[6.1]
  def change
    add_column :couriers, :deleted_at, :datetime
    add_index :couriers, :deleted_at
  end
end
