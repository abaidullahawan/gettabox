class AddDiscriptionInImportMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :import_mappings, :description, :text
  end
end
