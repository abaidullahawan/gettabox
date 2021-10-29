# frozen_string_literal: true

# product may have more products as child AKA multipack product
class MultipackProduct < ApplicationRecord
  belongs_to :product
  belongs_to :child, foreign_key: 'child_id', class_name: 'Product'
end
