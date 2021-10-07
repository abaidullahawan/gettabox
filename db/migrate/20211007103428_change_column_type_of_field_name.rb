class ChangeColumnTypeOfFieldName < ActiveRecord::Migration[6.1]
  def up
    change_column :extra_field_names, :field_name, :string
  end

  def down
    change_column :extra_field_names, :field_name, :text
  end
end
