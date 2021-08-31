class Product < ApplicationRecord
  acts_as_paranoid

  validates :sku, presence:true, uniqueness: { case_sensitive: false }
  validates :title, presence: true
  has_many :barcodes
  has_many :product_suppliers
  has_many :system_users, through: :product_suppliers

  belongs_to :category
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize: "100x100"
  end

  enum product_type: {
    Single: 0,
    Multiple: 1
  }, _prefix: true

  accepts_nested_attributes_for :barcodes, allow_destroy: true
  accepts_nested_attributes_for :product_suppliers, allow_destroy: true

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |product|
        csv << attributes.map{ |attr| product.send(attr) }
      end
    end
  end

end
