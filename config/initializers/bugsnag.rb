# frozen_string_literal: true

# Bugsnag for all environments
if Rails.env.production? || Rails.env.beta?
  Bugsnag.configure do |config|
    config.api_key = 'e6b975205ec2c546cf80f0d97fe77c8d'
  end
end
