class AddSelectedToMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    add_column :mail_service_rules, :selected, :boolean
  end
end
