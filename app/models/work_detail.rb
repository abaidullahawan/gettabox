# frozen_string_literal: true

# details of user
class WorkDetail < ApplicationRecord
  belongs_to :personal_detail
end
