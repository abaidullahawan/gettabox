class AddServiceRuleInProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_products, :mail_service_rule_id, :integer
  end
end
