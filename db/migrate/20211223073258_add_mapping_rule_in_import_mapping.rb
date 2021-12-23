class AddMappingRuleInImportMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :import_mappings, :mapping_rule, :json
  end
end
