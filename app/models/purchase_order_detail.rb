class PurchaseOrderDetail < ApplicationRecord
  belongs_to :purchase_order
  has_one :product
end
