class ChannelOrderItem < ApplicationRecord
    belongs_to :channel_order
    belongs_to :assign_rule, optional: true
end