# frozen_string_literal: true

json.extract! email_template, :id, :template_type, :template_name, :subject, :body, :created_at, :updated_at
json.url email_template_url(email_template, format: :json)
