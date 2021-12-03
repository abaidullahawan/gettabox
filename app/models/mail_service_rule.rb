# frozen_string_literal: true

# mail service rules for order items
class MailServiceRule < ApplicationRecord
  acts_as_paranoid
  belongs_to :channel_order, optional: true
  belongs_to :courier
  belongs_to :service
  has_many :mail_service_labels
  has_many :rules
  accepts_nested_attributes_for :mail_service_labels
  accepts_nested_attributes_for :rules

  enum label_type: {
    calculated_by_order: 0,
    label_per_item: 1,
    label_per_product: 2,
    label_from_products: 3
  }, _prefix: true

  enum csv_file: {
    dont_send_csv: 0,
    send_csv_with_label: 1,
    send_only_csv: 2
  }, _prefix: true

  enum rule_naming_type: {
    rule_name: 0,
    internal_rule_name: 1
  }, _prefix: true

  enum print_queue_type: {
    not_selected: 0,
    label: 1,
    secondary_label: 2,
    a4: 3,
    integrated_label: 4
  }, _prefix: true

  enum pickup_address: {
    default: 0
  }, _prefix: true

  enum manual_dispatch_label_template: {
    default: 0
  }, _prefix: true

  enum courier_account: {
    test: 0
  }, _prefix: true
end
