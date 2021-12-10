class AddAssignRuleToChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_reference :channel_orders, :assign_rule, null: true, foreign_key: true
  end
end
