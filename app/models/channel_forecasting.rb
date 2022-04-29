# frozen_string_literal: true

# rules assigned to channel order items
class ChannelForecasting < ApplicationRecord
  has_many :product_forecastings
  has_many :products, through: :product_forecastings

  enum filter_name: {
    supplier: 0,
    product_sku: 1,
    channel: 2
  }, _prefix: true

  enum action: {
    safe_stock_by: 0,
    anticipate_by: 1,
    anticipate_fake_stock_only_by: 2
  }, _prefix: true

  enum units: {
    product_units: 0,
    listing_units: 1,
    last_day_product_units_sold: 2
  }, _prefix: true

  enum filter_by_sku: {
    contains: 'contains',
    does_not_contain: 'does not contain',
    start_with: 'start with',
    end_with: 'end_with'
  }, _prefix: true

end
