class RemoveServiceRuleReferenceAndAddAssignRuleReference < ActiveRecord::Migration[6.1]
  def change
    remove_reference :channel_order_items, :mail_service_rule
    add_reference :channel_order_items, :assign_rule
    remove_reference :channel_products, :mail_service_rule
    add_reference :channel_products, :assign_rule
  end
end
