# frozen_string_literal: true

# MultiFile Mapping and download match and unmatch date into third CSV
class MultifileMapping < ApplicationRecord
  has_one_attached :attach_csv
end
