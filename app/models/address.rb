# frozen_string_literal: true

# address is polymorphic for multi tables
class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true
end
