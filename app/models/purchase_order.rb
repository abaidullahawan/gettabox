class PurchaseOrder < ApplicationRecord
  acts_as_paranoid
  has_many :addresses, as: :addressable
  belongs_to :system_user, foreign_key: 'supplier_id'
  has_many :purchase_order_details, dependent: :destroy
  has_many :purchase_deliveries, dependent: :destroy

  accepts_nested_attributes_for :purchase_order_details, allow_destroy: true

  enum order_status: {
    created: 0,
    sent: 1,
    completed: 2,
    partially_delivered: 3
  }, _prefix: true

  enum payment_method: {
    unpaid: 0,
    paid: 1
  }, _prefix: true

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |purchase_order|
        csv << attributes.map { |attr| purchase_order.send(attr) }
      end
    end
  end

  def self.to_single_csv(purchase_order)
    attributes = purchase_order.system_user.attributes.keys
    attributes2 = purchase_order.system_user.products.column_names
    attributes3 = purchase_order.purchase_deliveries.column_names
    CSV.generate(headers: true) do |csv|
      csv << ['', 'Supplier Record']
      csv << attributes.map { nil }
      csv << attributes
      csv << attributes.map { |attr| purchase_order.system_user.send(attr) }
      csv << attributes.map { nil }
      csv << attributes.map { nil }
      csv << ['', 'Products Record']
      csv << attributes.map { nil }
      csv << attributes2
      purchase_order.system_user.products.each do |pro|
        csv << attributes2.map { |attr| pro.send(attr) }
      end
      csv << attributes.map { nil }
      csv << attributes.map { nil }
      csv << ['', 'Delivery Details']
      csv << attributes.map { nil }
      csv << attributes3
      purchase_order.purchase_deliveries.each do |delivery|
        csv << attributes3.map { |attr| delivery.send(attr) }
      end
    end
  end
end
