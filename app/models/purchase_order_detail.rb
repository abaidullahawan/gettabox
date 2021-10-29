# frozen_string_literal: true

# order detail of product
class PurchaseOrderDetail < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_order
  belongs_to :product
end
