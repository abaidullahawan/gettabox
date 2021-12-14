# frozen_string_literal: true

# services belongs to courier for mailing orders
class Service < ApplicationRecord
  acts_as_paranoid

  belongs_to :courier
  has_many :mail_service_rules, dependent: :destroy
end
