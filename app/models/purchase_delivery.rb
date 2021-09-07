class PurchaseDelivery < ApplicationRecord
  belongs_to :purchase_order
  has_many :purchase_delivery_details

  accepts_nested_attributes_for :purchase_delivery_details, allow_destroy: true

end
