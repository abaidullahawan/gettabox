class ChannelOrderItem < ApplicationRecord
    belongs_to :channel_order
    belongs_to :mail_service_rule
end