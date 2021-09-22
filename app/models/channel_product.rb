class ChannelProduct < ApplicationRecord
  has_one :product_mapping

  enum channel_type: {
    ebay: 0,
    amazon: 1,
    shopify: 3,
  }, _prefix: true
end
