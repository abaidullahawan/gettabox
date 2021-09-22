class Product < ApplicationRecord
  acts_as_paranoid

  validates :sku, presence:true, uniqueness: { case_sensitive: false }
  validates :title, presence: true
  has_many :barcodes, dependent: :destroy
  has_many :product_suppliers, dependent: :destroy
  has_many :system_users, through: :product_suppliers
  has_many :multipack_products
  has_many :products, through: :multipack_products
  has_one :product_mapping

  belongs_to :category
  belongs_to :season, optional: true
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize: "100x100"
  end

  enum product_type: {
    single: 0,
    multiple: 1
  }, _prefix: true

  accepts_nested_attributes_for :barcodes, allow_destroy: true
  accepts_nested_attributes_for :product_suppliers, allow_destroy: true
  accepts_nested_attributes_for :multipack_products, allow_destroy: true


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
