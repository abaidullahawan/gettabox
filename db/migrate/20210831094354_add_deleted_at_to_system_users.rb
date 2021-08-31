class AddDeletedAtToSystemUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :system_users, :deleted_at, :datetime
    add_index :system_users, :deleted_at
  end
end
