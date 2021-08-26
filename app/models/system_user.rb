class SystemUser < ApplicationRecord
  has_many :product_suppliers
  has_many :products, through: :product_suppliers
  enum user_type: {
    customer: 0,
    supplier: 1
  }, _prefix: true

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |system_user|
        csv << attributes.map{ |attr| system_user.send(attr) }
      end
    end
  end

end
