class Service < ApplicationRecord
  belongs_to :courier
  has_many :mail_service_rules, dependent: :destroy
end
