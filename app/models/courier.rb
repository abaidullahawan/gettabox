# frozen_string_literal: true

# courier for mailing services
class Courier < ApplicationRecord
  acts_as_paranoid

  validates :name, presence: true, uniqueness: true
  has_many :services, dependent: :destroy
end
