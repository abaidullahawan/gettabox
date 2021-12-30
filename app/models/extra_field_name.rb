# frozen_string_literal: true

# user defined columns for products
class ExtraFieldName < ApplicationRecord
  validates_uniqueness_of :field_name
  has_many :extra_field_options
  accepts_nested_attributes_for :extra_field_options
end
