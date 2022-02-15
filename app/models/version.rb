# frozen_string_literal: true

# Version
class Version < ApplicationRecord
  belongs_to :channel_product, class_name: :ChannelProduct, foreign_key: :listing_id
end
