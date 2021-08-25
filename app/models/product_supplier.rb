class ProductSupplier < ApplicationRecord
  belongs_to :product
  belongs_to :system_user
end
