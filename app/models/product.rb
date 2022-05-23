# frozen_string_literal: true

# system products
class Product < ApplicationRecord
  acts_as_paranoid
  has_one :extra_field_value, as: :fieldvalueable
  belongs_to :product_location, optional: true
  after_create :re_modulate_dimensions
  after_create :available_stock_change
  after_update :re_modulate_dimensions
  after_update :update_channel_quantity, if: :saved_change_to_total_stock?

  validates :sku, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true
  attribute :allocated, :float, default: 0.0
  validates :total_stock, numericality: { greater_than_or_equal_to: :allocated }, if: -> { product_type_single? }
  has_many :barcodes, dependent: :destroy
  has_many :product_suppliers, dependent: :destroy
  has_many :system_users, through: :product_suppliers
  has_many :multipack_products, dependent: :destroy
  has_many :products, through: :multipack_products
  has_many :product_mappings, dependent: :destroy
  has_many :channel_order_items
  has_many :product_forecastings
  has_many :channel_forecastings, through: :product_forecastings

  belongs_to :category, optional: true
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
  accepts_nested_attributes_for :product_forecastings, allow_destroy: true
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
    return unless product_type.eql? 'single'

    update_columns(length: max, height: min, inventory_balance: (total_stock.to_i - unshipped.to_i),
                   unallocated: unshipped.to_i - allocated.to_i, available_stock: total_stock.to_i - allocated.to_i)
  end

  def update_channel_quantity
    product_mappings.each do |mapping|
      product = mapping.channel_product
      deduction_unit = 1
      if product.channel_type == 'ebay'
        channel_quantity = Selling&.last&.quantity.to_i < (inventory_balance.to_f/deduction_unit.to_f) ? Selling&.last&.quantity : [(inventory_balance.to_f/deduction_unit.to_f).floor, 0].max
      else
        channel_quantity = [(inventory_balance.to_f/deduction_unit.to_f).floor, 0].max
      end
      product.update(item_quantity: channel_quantity)
      # next unless Rails.env.production?

      # if product.channel_type_ebay? && (product.listing_type.eql? 'variation')
        # job_data = UpdateEbayVariationProductJob.perform_later(listing_id: product.listing_id, sku: product.item_sku, quantity: product.item_quantity)
        # JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbayVariationProductJob', status: 'Queued',
                        #  arguments: { listing_id: product.listing_id, sku: product.item_sku, quantity: product.item_quantity })
      # elsif product.channel_type_ebay? && (product.listing_type.eql? 'single')
        # job_data = UpdateEbaySingleProductJob.perform_later(listing_id: product.listing_id, quantity: product.item_quantity)
        # JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbaySingleProductJob', status: 'Queued',
                        #  arguments: { listing_id: product.listing_id, quantity: product.item_quantity })
      # end
    end
    @channel_listings = ChannelProduct.joins(product_mapping: [product: [multipack_products: :child]]).where('child.id': id)
    @channel_listings.each do |multi_mapping|
      deduction_unit = multi_mapping.product_mapping&.product&.multipack_products&.find_by(child_id: id)&.quantity.to_i
      deduction_quantity = [(inventory_balance.to_f/deduction_unit.to_f).floor, 0].max unless deduction_unit.zero?
      multipack_products = multi_mapping.product_mapping&.product&.multipack_products
      if multipack_products&.count.to_i > 1
        deduction_quantity = multi_products_check(multipack_products)
      end
      if multi_mapping.channel_type == 'ebay'
        channel_quantity =  Selling&.last&.quantity.to_i < deduction_quantity.to_i ? Selling&.last&.quantity.to_i: [deduction_quantity.to_i, 0].max
      else
        channel_quantity = [deduction_quantity.to_i, 0].max
      end
      multi_mapping.update(item_quantity: channel_quantity)
      # next unless Rails.env.production?

      # if multi_mapping.channel_type_ebay? && (multi_mapping.listing_type.eql? 'variation')
      #   job_data = UpdateEbayVariationProductJob.perform_later(listing_id: multi_mapping.listing_id, sku: multi_mapping.item_sku, quantity: multi_mapping.item_quantity)
      #   JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbayVariationProductJob', status: 'Queued',
      #                    arguments: { listing_id: multi_mapping.listing_id, sku: multi_mapping.item_sku, quantity: multi_mapping.item_quantity })
      # elsif multi_mapping.channel_type_ebay? && (multi_mapping.listing_type.eql? 'single')
      #   job_data = UpdateEbaySingleProductJob.perform_later(listing_id: multi_mapping.listing_id, quantity: multi_mapping.item_quantity)
      #   JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbaySingleProductJob', status: 'Queued',
      #                    arguments: { listing_id: multi_mapping.listing_id, quantity: multi_mapping.item_quantity })
      # end
    end
  end

  def multi_products_check(multipack_products)
    deduction_arr = []
    multipack_products.each do |multipack_product|
      deduction_arr.push(multipack_product.child.inventory_balance.to_i / multipack_product.quantity.to_i) unless multipack_product.quantity.to_i.zero?
    end
    deduction_arr.min
  end

  def available_stock_change
    update_columns(available_stock: total_stock)
  end

  def call_amazon_product_job(sku, quantity)
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now  + 130.seconds: wait_time + 130.seconds
    credential.update(redirect_uri: 'UpdateAmazonProduct', authorization: sku, created_at: wait_time)
    elapsed_seconds = wait_time - DateTime.now
    # UpdateAmazonProduct.set(wait: elapsed_seconds.seconds).perform_later(product: sku, quantity: quantity)
  end
end
