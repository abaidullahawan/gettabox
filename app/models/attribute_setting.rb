# frozen_string_literal: true

# for setting attributes of tables different for all user or default
class AttributeSetting < ApplicationRecord
  belongs_to :user

  enum setting_type: {
    index: 0,
    pdf: 1,
    csv: 2
  }, _prefix: true
end
