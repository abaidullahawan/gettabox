# frozen_string_literal: true

# values of user defined columns for products
class ExtraFieldValue < ApplicationRecord
  belongs_to :fieldvalueable, polymorphic: true
end
