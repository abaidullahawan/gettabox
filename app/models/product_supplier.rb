# frozen_string_literal: true

# product supplier is also our system user
class ProductSupplier < ApplicationRecord
  validates_uniqueness_of :product_sku, allow_nil: true
  belongs_to :product
  belongs_to :system_user
end
