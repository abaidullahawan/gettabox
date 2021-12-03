class AddServiceRuleToChannelOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_order_items, :mail_service_rule
  end
end
