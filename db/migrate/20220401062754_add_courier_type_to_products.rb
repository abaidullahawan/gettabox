class AddCourierTypeToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :courier_type, :string
  end
end
