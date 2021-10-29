# frozen_string_literal: true

# quantity of product
class Quantity < ApplicationRecord
  belongs_to :product
end
