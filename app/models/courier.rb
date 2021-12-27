# frozen_string_literal: true

# courier for mailing services
class Courier < ApplicationRecord
  acts_as_paranoid

  validates :name, presence: true, uniqueness: true
  has_many :services, dependent: :destroy

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
