# frozen_string_literal: true

# channel order has many order replacements
class OrderReplacement < ApplicationRecord
  belongs_to :channel_order
  belongs_to :order_replacement, foreign_key: 'order_replacement_id', class_name: 'ChannelOrder'
end
