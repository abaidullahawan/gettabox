class Season < ApplicationRecord
  acts_as_paranoid
  has_many :products
  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |season|
        csv << attributes.map{ |attr| season.send(attr) }
      end
    end
  end
end
