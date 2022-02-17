# frozen_string_literal: true

# Product has one location
class ProductLocation < ApplicationRecord
  has_many :products
end
