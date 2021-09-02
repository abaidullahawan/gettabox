class AddDeletedAtToSeasons < ActiveRecord::Migration[6.1]
  def change
    add_column :seasons, :deleted_at, :datetime
    add_index :seasons, :deleted_at
  end
end
