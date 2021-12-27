class AddSelectedToCategories < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :selected, :boolean
  end
end
