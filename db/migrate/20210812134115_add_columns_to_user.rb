class AddColumnsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :role, :integer
    add_column :users, :created_by, :integer, null: true, index: true
    add_foreign_key :users, :users, column: :created_by
  end
end
