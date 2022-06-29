# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Credential
  .create(redirect_uri: 'Channel_Dispatc-ChannelD-Channe-flynitdm',
          grant_type: 'refresh_token',
          authorization: 'Basic Q2hhbm5lbEQtQ2hhbm5lbEQtUFJELWRhMjhlYzY5MC00YTlmMzYzYzpQUkQtYTI4ZWM2OTA4ZWE5LTdjNDMtNGZkOS1iZTQzLTBlN2Q=')

Credential
  .create(grant_type: 'wait_time')

User.new(email: 'developer@devbox.co', password: 'devbox123', password_confirmation: 'devbox123', role: 'super_admin')
    .build_personal_detail(first_name: 'Devbox', last_name: 'Developer')
    .save

Category.create(title: 'temporary products')