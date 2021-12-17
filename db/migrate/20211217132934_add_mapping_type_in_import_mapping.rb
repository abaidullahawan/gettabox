class AddMappingTypeInImportMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :import_mappings, :mapping_type, :string
  end
end
