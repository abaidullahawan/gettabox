class PurchaseDeliveryDetail < ApplicationRecord
  belongs_to :purchase_delivery
  belongs_to :product
end
