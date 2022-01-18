# frozen_string_literal: true

# Note for customer(may be used in other tables)
class Note < ApplicationRecord
  belongs_to :user
  belongs_to :reference, polymorphic: true
end
