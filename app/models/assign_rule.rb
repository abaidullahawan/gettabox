# frozen_string_literal: true

# rules assigned to channel order items
class AssignRule < ApplicationRecord
  has_many :channel_order_items
  has_many :channel_products
  belongs_to :mail_service_rule
  has_many :mail_service_labels
  accepts_nested_attributes_for :mail_service_labels
end
