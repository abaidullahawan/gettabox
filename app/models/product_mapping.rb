class ProductMapping < ApplicationRecord
  belongs_to :product
  belongs_to :channel_product
end
