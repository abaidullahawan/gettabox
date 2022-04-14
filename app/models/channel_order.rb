# frozen_string_literal: true

# orders from api
class ChannelOrder < ApplicationRecord
  has_many :channel_order_items, dependent: :destroy
  has_many :trackings
  has_one :mail_service_rule, dependent: :destroy
  belongs_to :order_batch, optional: true
  belongs_to :assign_rule, optional: true
  belongs_to :channel_order, optional: true
  belongs_to :system_user, optional: true
  accepts_nested_attributes_for :channel_order_items
  accepts_nested_attributes_for :trackings
  has_many :order_replacements
  has_many :notes, as: :reference
  has_many :channel_orders, through: :order_replacements

  after_create :set_postage
  after_update :set_postage

  enum channel_type: {
    ebay: 0,
    amazon: 1,
    shopify: 3,
    manual_order: 4
  }, _prefix: true

  enum stage: {
    completed: 'Completed',
    unpaid: 'Unpaid',
    pending: 'Pending',
    canceled: 'Canceled',
    issue: 'Issue',
    ready_to_dispatch: 'Ready to dispatch',
    ready_to_print: 'Ready to print',
    unable_to_find_sku: 'Unable to find SKU',
    unmapped_product_sku: 'Unmapped product SKU'
  }, _prefix: true

  def self.find_product(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product
  end

  def self.check_mapping(product)
    ChannelProduct.find_by(item_sku: product.sku)&.status
  end

  def self.check_type(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product&.product_type
  end

  def self.product_sku(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product&.sku
  end

  def self.product_location(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product&.location
  end

  # def self.picture_check(product)
  #   ChannelProduct.find_by(item_sku: product.sku)&.product_data.present? && !ChannelProduct.find_by(item_sku: product.sku)&.product_data['PictureDetails'].nil?
  # end

  # def self.picture_data(product)
  #   ChannelProduct.find_by(item_sku: product.sku)&.product_data['PictureDetails']['GalleryURL']
  # end

  private

  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999')")
  end

  # ransacker :assign_rule_id do
  #   Arel.sql('COALESCE(assign_rule_id, 0)')
  # end

  def set_postage
    postage_hash = {'Standard' => '0.0', 'SecondDay' => '2.99', 'Expedited' => '2.99'}

    return if postage.to_f.to_s.eql? postage

    update_columns(postage: postage_hash[postage])
  end
end
