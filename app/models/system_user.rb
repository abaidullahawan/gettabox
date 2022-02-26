# frozen_string_literal: true

# Any user who uses our system
class SystemUser < ApplicationRecord
  acts_as_paranoid

  has_many :product_suppliers
  has_many :products, through: :product_suppliers
  has_many :channel_orders
  has_one :extra_field_value, as: :fieldvalueable
  has_many :purchase_orders, foreign_key: 'supplier_id', primary_key: 'id', dependent: :destroy
  validates :name, presence: true
  # validates :email, presence: true, if: -> { user_type_supplier? }
  # validates :phone_number, presence: true, if: -> { user_type_supplier? }
  validates :email
  validates :phone_number
  has_one_attached :photo
  has_many :addresses, as: :addressable
  has_many :notes, as: :reference
  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :extra_field_value
  enum user_type: {
    customer: 0,
    supplier: 1
  }, _prefix: true

  enum sales_channel: {
    ebay: 'ebay',
    amazon: 'Amazon',
    shopify: 'shopify',
    manual_order: 'manual_order'
  }, _prefix: true

  enum payment_method: {
    debit: 0,
    credit: 1
  }, _prefix: true

  enum delivery_method: {
    shipping: 0,
    local_delivery: 1,
    local_pickup: 2,
    self_pickup: 3
  }, _prefix: true

  scope :suppliers, -> { where(user_type: 'supplier') }
  scope :customers, -> { where(user_type: 'customer') }

  def self.to_csv
    attributes = all.column_names.excluding('user_type')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |system_user|
        csv << attributes.map { |attr| system_user.send(attr) }
      end
    end
  end
end
