class AddTrackingImportToMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    add_column :mail_service_rules, :tracking_import, :boolean
  end
end
