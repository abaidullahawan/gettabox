# frozen_string_literal: true

# mail service rules for order items
class MailServiceRule < ApplicationRecord
  acts_as_paranoid
  belongs_to :channel_order, optional: true
  belongs_to :courier
  belongs_to :service, optional: true
  has_many :rules
  belongs_to :export_mapping, optional: true
  has_many :assign_rule, dependent: :destroy
  accepts_nested_attributes_for :rules, allow_destroy: true

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

  enum courier_account: {
    test: 0
  }, _prefix: true

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |category|
        csv << attributes.map { |attr| category.send(attr) }
      end
    end
  end
end
