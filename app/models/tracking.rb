class Tracking < ApplicationRecord
    belongs_to :channel_order, optional: true
end
