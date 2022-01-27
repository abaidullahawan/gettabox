class AddChangeLogInProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :change_log, :string
  end
end
