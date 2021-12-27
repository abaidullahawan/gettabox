class AddSelectedToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :selected, :boolean
  end
end
