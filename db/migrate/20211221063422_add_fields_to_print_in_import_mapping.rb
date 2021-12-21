class AddFieldsToPrintInImportMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :import_mappings, :data_to_print, :json
  end
end
