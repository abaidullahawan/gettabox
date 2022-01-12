# frozen_string_literal: true

# product details of order
class ChannelOrderItem < ApplicationRecord
  belongs_to :channel_order
  belongs_to :assign_rule, optional: true
  belongs_to :channel_product, optional: true
  belongs_to :product, optional: true

  enum sales_channel: {
    ebay: 0,
    amazon: 1,
    shopify: 3,
    manual_order: 4
  }, _prefix: true
end
