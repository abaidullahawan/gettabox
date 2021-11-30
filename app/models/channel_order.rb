# frozen_string_literal: true

# orders from api
class ChannelOrder < ApplicationRecord
  has_many :channel_order_items, dependent: :destroy
  has_many :fulfillment_instructions, dependent: :destroy
  has_one :mail_service_rule, dependent: :destroy
  validates_uniqueness_of :order_data
  validates_uniqueness_of :ebayorder_id
  enum channel_type: {
    ebay: 0,
    amazon: 1,
    shopify: 3
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

  def self.picture_check(product)
    ChannelProduct.find_by(item_sku: product.sku )&.product_data.present?  && ChannelProduct.find_by(item_sku: product.sku )&.product_data["PictureDetails"] != nil
  end

  def self.picture_data(product)
    ChannelProduct.find_by(item_sku: product.sku )&.product_data["PictureDetails"]["GalleryURL"]
  end
end
