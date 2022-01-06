class AddExportMappingReferenceToMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    add_reference :mail_service_rules, :export_mapping, null: true, foreign_key: true
  end
end
