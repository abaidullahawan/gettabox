class Barcode < ApplicationRecord
  validates_uniqueness_of :title
  belongs_to :product
end
