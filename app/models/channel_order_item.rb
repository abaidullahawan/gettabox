# frozen_string_literal: true

# product details of order
class ChannelOrderItem < ApplicationRecord
  belongs_to :channel_order
  belongs_to :assign_rule, optional: true
  belongs_to :channel_product, optional: true
end
