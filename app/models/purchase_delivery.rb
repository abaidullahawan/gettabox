# frozen_string_literal: true

# single delivery may be many delivery details
class PurchaseDelivery < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_order
  has_many :purchase_delivery_details, dependent: :destroy

  accepts_nested_attributes_for :purchase_delivery_details, allow_destroy: true

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |purchase_delivery|
        csv << attributes.map { |attr| purchase_delivery.send(attr) }
      end
    end
  end
end
