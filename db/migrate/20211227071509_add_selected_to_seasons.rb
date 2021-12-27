class AddSelectedToSeasons < ActiveRecord::Migration[6.1]
  def change
    add_column :seasons, :selected, :boolean
  end
end
