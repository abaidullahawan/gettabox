class AddFieldTypeToExtraFieldName < ActiveRecord::Migration[6.1]
  def change
    add_column :extra_field_names, :field_type, :string
  end
end
