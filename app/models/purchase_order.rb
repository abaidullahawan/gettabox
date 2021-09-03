class PurchaseOrder < ApplicationRecord
  belongs_to :supplier
  has_many :purchase_order_details
end
