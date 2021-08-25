class Product < ApplicationRecord

  validates :sku, uniqueness: { case_sensitive: false }
  has_many :barcodes
  has_many :product_suppliers
  has_many :system_users, through: :product_suppliers

  has_one :category
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize: "100x100"
  end

  accepts_nested_attributes_for :barcodes, allow_destroy: true
  accepts_nested_attributes_for :system_users, allow_destroy: true

end
