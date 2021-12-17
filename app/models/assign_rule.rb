# frozen_string_literal: true

# rules assigned to channel order items
class AssignRule < ApplicationRecord
  has_many :channel_orders
  belongs_to :mail_service_rule
  has_many :mail_service_labels
  accepts_nested_attributes_for :mail_service_labels
  before_destroy :update_channel_order

  enum status: {
    unready: 0,
    ready: 1,
    printed: 2,
    part_ready: 3,
    customized: 4
  }, _prefix: true

  def update_channel_order
    channel_orders.update_all(assign_rule_id: nil)
  end
end
