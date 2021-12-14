# frozen_string_literal: true

json.array! @mail_service_rules, partial: 'mail_service_rules/mail_service_rule', as: :mail_service_rule
