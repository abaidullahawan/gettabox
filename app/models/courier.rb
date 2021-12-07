class Courier < ApplicationRecord
  acts_as_paranoid

  has_many :services, dependent: :destroy
end
