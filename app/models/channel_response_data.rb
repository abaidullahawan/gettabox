class ChannelResponseData < ApplicationRecord
  enum channel: {
    ebay: 0,
    amazon: 1,
    shopify: 3,
  }, _prefix: true
end