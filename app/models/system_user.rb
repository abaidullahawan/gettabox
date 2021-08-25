class SystemUser < ApplicationRecord
  has_many :product_suppliers
  has_many :products, through: :product_suppliers
  enum user_type: {
    customer: 0,
    supplier: 1
  }, _prefix: true
end
