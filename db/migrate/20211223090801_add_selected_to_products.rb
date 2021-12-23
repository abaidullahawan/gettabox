class AddSelectedToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :selected, :boolean
  end
end
