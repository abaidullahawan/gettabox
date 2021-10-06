class ChannelOrder < ApplicationRecord
  validates_uniqueness_of :order_data
  enum channel_type: {
    ebay: 0,
    amazon: 1,
    shopify: 3,
  }, _prefix: true
end
