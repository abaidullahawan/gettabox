# frozen_string_literal: true

# orders from api
class ChannelOrder < ApplicationRecord
  has_many :channel_order_items, dependent: :destroy
  validates_uniqueness_of :order_data
  validates_uniqueness_of :ebayorder_id
  enum channel_type: {
    ebay: 0,
    amazon: 1,
    shopify: 3
  }, _prefix: true

  def self.find_product(product)
    ChannelProduct.find_by(item_sku: product.sku).product_mapping.product.location
  end

  def self.check_mapping(product)
    ChannelProduct.find_by(item_sku: product.sku).status
  end

  def self.check_type(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product&.product_type
  end

  def self.product_title(product)
    ChannelProduct.find_by(item_sku: product.sku)&.product_mapping&.product&.title
  end
end
