class Category < ApplicationRecord
  has_many :products

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |category|
        csv << attributes.map{ |attr| category.send(attr) }
      end
    end
  end

end
