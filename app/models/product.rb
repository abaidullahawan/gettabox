class Product < ApplicationRecord

  validates :sku, presence:true, uniqueness: { case_sensitive: false }
  validates :title, presence: true
  has_many :barcodes
  has_many :product_suppliers
  has_many :system_users, through: :product_suppliers

  has_one :category
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize: "100x100"
  end

  accepts_nested_attributes_for :barcodes, allow_destroy: true
  accepts_nested_attributes_for :system_users, allow_destroy: true

  enum product_type: {
    single: 0,
    multiple: 1
  }, _prefix: true

end
