# frozen_string_literal: true

# joining products(system) and channel product(api) together
class ProductMapping < ApplicationRecord
  belongs_to :product
  belongs_to :channel_product
end
