# frozen_string_literal: true

# product supplier is also our system user
class ProductSupplier < ApplicationRecord
  validates_uniqueness_of :product_sku, allow_nil: true
  belongs_to :product
  belongs_to :system_user

  enum product_vat: {
    zero_rate: 0.0,
    reduced_rate: 1.0,
    extra_reduced_rate: 2.0,
    super_reduced_rate: 3.0,
    flat_rate: 4.0,
    standard_rate: 5.0,
    ecg_exempt: 10.0,
    vat_exempt: 20.0
  }, _prefix: true
end
