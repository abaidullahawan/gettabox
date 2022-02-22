# frozen_string_literal: true

# system products
class Product < ApplicationRecord
  acts_as_paranoid
  has_one :extra_field_value, as: :fieldvalueable
  belongs_to :product_location, optional: true
  after_create :re_modulate_dimensions
  after_create :available_stock_change
  after_update :re_modulate_dimensions

  validates :sku, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true
  attribute :allocated_orders, :float, default: 0.0
  validates :total_stock, numericality: { greater_than_or_equal_to: :allocated_orders }, if: -> { product_type_single? }
  has_many :barcodes, dependent: :destroy
  has_many :product_suppliers, dependent: :destroy
  has_many :system_users, through: :product_suppliers
  has_many :multipack_products, dependent: :destroy
  has_many :products, through: :multipack_products
  has_many :product_mappings
  has_many :channel_order_items

  belongs_to :category
  belongs_to :season, optional: true
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize: '100x100'
  end

  enum product_type: {
    single: 0,
    multiple: 1
  }, _prefix: true

  enum vat: {
    zero_rate: 0,
    reduced_rate: 1,
    extra_reduced_rate: 2,
    super_reduced_rate: 3,
    flat_rate: 4,
    standard_rate: 5,
    ecg_exempt: 10,
    vat_exempt: 20
  }, _prefix: true

  accepts_nested_attributes_for :barcodes, allow_destroy: true
  accepts_nested_attributes_for :product_suppliers, allow_destroy: true
  accepts_nested_attributes_for :multipack_products, allow_destroy: true
  accepts_nested_attributes_for :extra_field_value

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |product|
        csv << attributes.map { |attr| product.send(attr) }
      end
    end
  end

  def re_modulate_dimensions
    max = [length, height].max
    min = [length, height].min
    update_columns(length: max, height: min, inventory_balance: (total_stock.to_i - unshipped.to_i),
                   unallocated: unshipped.to_i - allocated_orders.to_i)
  end

  def available_stock_change
    update_columns(available_stock: total_stock)
  end
end
