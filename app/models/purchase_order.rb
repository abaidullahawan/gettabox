class PurchaseOrder < ApplicationRecord
  belongs_to :system_user, foreign_key: 'supplier_id'
  has_many :purchase_order_details

  accepts_nested_attributes_for :purchase_order_details, allow_destroy: true

end
