# frozen_string_literal: true

# system user's defined setting
class GeneralSetting < ApplicationRecord
  has_one :address, as: :addressable
  accepts_nested_attributes_for :address
end
