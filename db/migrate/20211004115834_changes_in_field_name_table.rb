class ChangesInFieldNameTable < ActiveRecord::Migration[6.1]
  def change
    remove_reference :extra_field_names, :fieldnameable, polymorphic: true
    add_column :extra_field_names, :table_name, :string
  end
end
