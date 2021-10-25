class Category < ApplicationRecord
  acts_as_paranoid
  has_many :products
  validates :title, presence: true

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
