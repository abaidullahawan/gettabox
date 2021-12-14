# frozen_string_literal: true

json.extract! courier, :id, :name, :created_at, :updated_at
json.url courier_url(courier, format: :json)
