# frozen_string_literal: true

# user defined columns for products
class ExtraFieldName < ApplicationRecord
  validates_uniqueness_of :field_name
end
