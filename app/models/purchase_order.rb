# frozen_string_literal: true

# single order may have many order details, made for  product supplier
class PurchaseOrder < ApplicationRecord
  acts_as_paranoid
  has_many :addresses, as: :addressable
  belongs_to :system_user, foreign_key: 'supplier_id'
  has_many :purchase_order_details, dependent: :destroy
  has_many :purchase_deliveries, dependent: :destroy

  has_one_attached :invoice

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
    supplier_attr = purchase_order.system_user.attributes.keys
    product_attr = purchase_order.system_user.products.column_names
    delivery_detail_attr = purchase_order.purchase_deliveries.column_names
    CSV.generate(headers: true) do |csv|
      supplier_records(csv, supplier_attr, purchase_order)

      product_records(csv, product_attr, purchase_order)

      delivery_details_records(csv, delivery_detail_attr, purchase_order)
    end
  end

  def self.supplier_records(csv, attributes, purchase_order)
    csv << ['', 'Supplier Record']
    put_empty_line(csv, attributes)
    csv << attributes
    csv << attributes.map { |attr| purchase_order.system_user.send(attr) }
    put_empty_line(csv, attributes)
    put_empty_line(csv, attributes)
  end

  def self.product_records(csv, attributes, purchase_order)
    csv << ['', 'Products Record']
    put_empty_line(csv, attributes)
    csv << attributes
    purchase_order.system_user.products.each do |pro|
      csv << attributes.map { |attr| pro.send(attr) }
    end
    put_empty_line(csv, attributes)
    put_empty_line(csv, attributes)
  end

  def self.delivery_details_records(csv, attributes, purchase_order)
    csv << ['', 'Delivery Details']
    put_empty_line(csv, attributes)
    csv << attributes
    purchase_order.purchase_deliveries.each do |delivery|
      csv << attributes.map { |attr| delivery.send(attr) }
    end
  end

  def self.put_empty_line(csv, attributes)
    csv << attributes.map { nil }
  end
end
