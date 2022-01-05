class AddExportMappingToServices < ActiveRecord::Migration[6.1]
  def change
    add_reference :services, :export_mapping, null: true, foreign_key: true
  end
end
