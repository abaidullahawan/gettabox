class AddHeaderDataFieldInImportSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :import_mappings, :header_data, :json
    add_column :import_mappings, :table_data, :json
  end
end
