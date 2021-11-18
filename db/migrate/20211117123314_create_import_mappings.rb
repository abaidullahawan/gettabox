class CreateImportMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :import_mappings do |t|
      t.string :table_name
      t.json :mapping_data, default: {}

      t.timestamps
    end
  end
end
