# frozen_string_literal: true

# products from apo
class ChannelProduct < ApplicationRecord
  has_one :product_mapping

  enum channel_type: {
    ebay: 0,
    amazon: 1,
    cloud_commerce: 4
  }, _prefix: true

  enum status: {
    unmapped: 0,
    mapped: 1
  }, _prefix: true
end
