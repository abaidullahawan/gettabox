# frozen_string_literal: true

# unique string indentifier for product
class Barcode < ApplicationRecord
  validates_uniqueness_of :title
  belongs_to :product
end
