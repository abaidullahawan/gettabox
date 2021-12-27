# frozen_string_literal: true

# services belongs to courier for mailing orders
class Service < ApplicationRecord
  acts_as_paranoid

  belongs_to :courier
  has_many :mail_service_rules, dependent: :destroy

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |category|
        csv << attributes.map { |attr| category.send(attr) }
      end
    end
  end
end
