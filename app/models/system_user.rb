class SystemUser < ApplicationRecord
  has_many :product_suppliers
  has_many :products, through: :product_suppliers
  validates :name, presence: true
  has_one_attached :photo

  enum user_type: {
    customer: 0,
    supplier: 1
  }, _prefix: true

  enum payment_method: {
    debit: 0,
    credit: 1
  }, _prefix: true

  enum delivery_method: {
    shipping: 0,
    local_delivery: 1,
    local_pickup: 2,
    self_pickup: 3
  }, _prefix: true

  def self.to_csv
    attributes = all.column_names.excluding('user_type')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |system_user|
        csv << attributes.map{ |attr| system_user.send(attr) }
      end
    end
  end

end
