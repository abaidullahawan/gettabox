# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Using Devise
gem 'devise'
gem 'devise-bootstrap-views'
gem 'devise-i18n'

gem 'font-awesome-rails'
gem 'roo', '~> 2.8'
gem 'spreadsheet'
# Use for nested forms
gem 'activerecord-import'
gem 'bootstrap4-kaminari-views'
gem 'cocoon'
gem 'ransack'

# Use for amazon s3 bucket
gem 'aws-sdk-s3', require: false
gem 'aws-sdk-signer'
gem 'image_processing'
gem 'mini_magick'
# gem for super admin
gem 'administrate'
# soft delete handling
gem 'paranoia', '~> 2.2'
# Use for dropdown searching
gem 'chosen-rails'
gem 'jquery-rails'
# Gem for PDF's
# PDF
gem 'wicked_pdf', github: 'mileszs/wicked_pdf'
gem 'wkhtmltopdf-binary'
# Paper Trail
gem 'paper_trail'
# for deep nested hash
gem 'dig-deep'

gem 'http'
gem 'httparty'
gem 'rest-client'

gem 'builder'
gem 'rexml', '~> 3.2.4'

gem 'capistrano-sidekiq'
gem 'redis-namespace', '~> 1.8.1'
gem 'sidekiq'

gem 'capistrano', '~> 3.11'
gem 'capistrano-passenger', '~> 0.2.0'
gem 'capistrano-rails', '~> 1.4'
gem 'capistrano-rbenv', '~> 2.1', '>= 2.1.4'
gem 'sidekiq-scheduler'
gem 'sshkit-sudo'

gem 'config'
gem 'rubocop', require: false
gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version
gem 'zip-zip' # will load compatibility for old rubyzip API.


# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Combine two PDF
gem 'combine_pdf'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'listen', '~> 3.3'
  gem 'rack-mini-profiler', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# ADD TRANSPILER TO USE ES6
gem 'sprockets'
gem 'sprockets-es6'

group :production, :beta do
  gem 'bugsnag'
end
