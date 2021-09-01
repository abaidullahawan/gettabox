class AddSeasonRefToProducts < ActiveRecord::Migration[6.1]
  def change
    add_reference :products, :season, null: true, foreign_key: true
  end
end
