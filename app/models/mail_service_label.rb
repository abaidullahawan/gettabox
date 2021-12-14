# frozen_string_literal: true

# service used for mailing orders
class MailServiceLabel < ApplicationRecord
  belongs_to :assign_rule
end
