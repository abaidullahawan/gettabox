# frozen_string_literal: true

# mapping used for importing csv files
class ImportMapping < ApplicationRecord
  validates_uniqueness_of :sub_type
  validates :sub_type, presence: true
end
