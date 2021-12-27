class CreateExportMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :export_mappings do |t|
      t.string :table_name
      t.string :sub_type
      t.json :export_data

      t.timestamps
    end
  end
end
