# frozen_string_literal: true

# order detail of product
class PurchaseOrderDetail < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_order
  belongs_to :product

  enum quantity_type: {
    single: 0,
    pack_quantity: 1,
    pallet_quantity: 2
  }, _prefix: true
end
