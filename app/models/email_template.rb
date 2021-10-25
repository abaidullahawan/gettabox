class EmailTemplate < ApplicationRecord
  validates :template_name, presence: true, uniqueness: { case_sensitive: false }
end
