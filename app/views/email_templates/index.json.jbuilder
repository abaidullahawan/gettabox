# frozen_string_literal: true

json.array! @email_templates, partial: 'email_templates/email_template', as: :email_template
