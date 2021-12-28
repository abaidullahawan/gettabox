class AddSelectedToSystemUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :system_users, :selected, :boolean
  end
end
