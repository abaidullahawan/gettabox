class AddSelectedToCouriers < ActiveRecord::Migration[6.1]
  def change
    add_column :couriers, :selected, :boolean
  end
end
