class PurchaseOrder < ApplicationRecord
  belongs_to :system_user, foreign_key: 'supplier_id'
  has_many :purchase_order_details

  accepts_nested_attributes_for :purchase_order_details, reject_if: :check_rejectable?, allow_destroy: true
  def check_rejectable?(attributes)
    if attributes['cost_price'].blank? && attributes['quantity'].blank?
      return true
    else
      return false
    end
  end

end
