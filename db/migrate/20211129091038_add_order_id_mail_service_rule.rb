class AddOrderIdMailServiceRule < ActiveRecord::Migration[6.1]
  def change
    add_reference :mail_service_rules, :channel_order
    remove_reference :mail_service_labels, :mail_service_role
    add_reference :mail_service_labels, :mail_service_rule
  end
end
