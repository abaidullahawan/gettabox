# frozen_string_literal: true

# rules assigned to channel order items
class ChannelForecasting < ApplicationRecord
  belongs_to :product_forecasting

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
    order_units: 1,
    last_day_product_units_sold: 2
  }, _prefix: true

end
