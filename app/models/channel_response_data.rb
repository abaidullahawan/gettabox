# frozen_string_literal: true

# bulk response from api
class ChannelResponseData < ApplicationRecord
  enum channel: {
    ebay: 0,
    amazon: 1,
    shopify: 3
  }, _prefix: true
  enum status: {
    executed: 'executed',
    not_available: 'not available',
    error: 'error',
    pending: 'pending',
    partial: 'partial'
  }, _prefix: true
end
