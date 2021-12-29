class AddColumnsToExportMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :export_mappings, :mapping_data, :json
  end
end
