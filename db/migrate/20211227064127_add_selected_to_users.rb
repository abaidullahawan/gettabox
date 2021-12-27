class AddSelectedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :selected, :boolean
  end
end
