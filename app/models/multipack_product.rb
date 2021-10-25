class MultipackProduct < ApplicationRecord
  belongs_to :product
  belongs_to :child, foreign_key: 'child_id', class_name: 'Product'
end
