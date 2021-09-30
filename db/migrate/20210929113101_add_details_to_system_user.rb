class AddDetailsToSystemUser < ActiveRecord::Migration[6.1]
  def change
    add_column :system_users, :email, :string
    add_column :system_users, :phone_number, :string
  end
end
