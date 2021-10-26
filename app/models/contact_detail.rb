# frozen_string_literal: true

# contact details
class ContactDetail < ApplicationRecord
  belongs_to :personal_detail
end
