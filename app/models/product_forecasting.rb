# frozen_string_literal: true

class ProductForecasting < ApplicationRecord
  belongs_to :product
  belongs_to :channel_forecasting
end
