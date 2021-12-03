class AddDeletedAtToMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    add_column :mail_service_rules, :deleted_at, :datetime
    add_index :mail_service_rules, :deleted_at
  end
end
