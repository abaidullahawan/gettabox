# frozen_string_literal: true

class ProductForecasting < ApplicationRecord
  has_many :products
  has_many :channel_forecastings

  accepts_nested_attributes_for :channel_forecastings, allow_destroy: true
end
