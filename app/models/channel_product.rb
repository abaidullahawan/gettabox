# frozen_string_literal: true

# products from apo
class ChannelProduct < ApplicationRecord
  has_one :product_mapping
  belongs_to :assign_rule, optional: true
  belongs_to :channel_forecasting, optional: true
  has_many :channel_order_items
  after_update :quantity_update, if: :item_quantity?
  enum channel_type: {
    ebay: 0,
    amazon: 1,
    cloud_commerce: 4
  }, _prefix: true

  enum status: {
    unmapped: 0,
    mapped: 1
  }, _prefix: true

  def quantity_update
    return unless Rails.env.production?
    if channel_type_ebay?
      UpdateEbayProduct.perform_now(listing_id: listing_id, sku: item_sku, quantity: item_quantity)
    else
      UpdateAmazonProduct.perform_now(product: item_sku, quantity: item_quantity)
    end
  end
end
