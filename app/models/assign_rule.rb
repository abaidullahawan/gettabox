# frozen_string_literal: true

# rules assigned to channel order items
class AssignRule < ApplicationRecord
  has_many :channel_orders
  belongs_to :mail_service_rule
  has_many :mail_service_labels
  accepts_nested_attributes_for :mail_service_labels

  enum status: {
    unready: 0,
    ready: 1,
    printed: 2,
    part_ready: 3
  }
end
