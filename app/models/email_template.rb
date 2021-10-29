# frozen_string_literal: true

# user defined templates or default
class EmailTemplate < ApplicationRecord
  validates :template_name, presence: true, uniqueness: { case_sensitive: false }
end
