class ChangeNameOfDescriptionInImportMapping < ActiveRecord::Migration[6.1]
  def change
    rename_column :import_mappings, :description, :sub_type
  end
end
