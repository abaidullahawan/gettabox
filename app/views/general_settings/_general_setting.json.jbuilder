# frozen_string_literal: true

json.extract! general_setting, :id, :name, :display_name, :phone, :address, :created_at, :updated_at
json.url general_setting_url(general_setting, format: :json)
