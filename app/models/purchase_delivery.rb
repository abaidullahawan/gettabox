class PurchaseDelivery < ApplicationRecord
  belongs_to :purchase_order
  has_many :purchase_delivery_details

end
