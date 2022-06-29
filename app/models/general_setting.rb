# frozen_string_literal: true

# system user's defined setting
class GeneralSetting < ApplicationRecord
  has_many :addresses, as: :addressable
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
