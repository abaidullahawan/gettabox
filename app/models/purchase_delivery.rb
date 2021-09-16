class PurchaseDelivery < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_order
  has_many :purchase_delivery_details, dependent: :destroy

  accepts_nested_attributes_for :purchase_delivery_details, allow_destroy: true

end
