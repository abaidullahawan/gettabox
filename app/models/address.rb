# frozen_string_literal: true

# address is polymorphic for multi tables
class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  enum address_title: {
    admin: 'admin',
    billing: 'billing',
    delivery: 'delivery'
  }, _prefix: true
end
