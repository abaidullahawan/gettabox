class Product < ApplicationRecord
  has_many :barcodes
  has_many :system_users

  has_one :category
  has_one_attached :image

  accepts_nested_attributes_for :barcodes, allow_destroy: true

end
