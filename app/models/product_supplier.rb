class ProductSupplier < ApplicationRecord
  validates_uniqueness_of :product_sku
  belongs_to :product
  belongs_to :system_user
end
