# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
# Default branch is :master
set :branch, 'staging'
set :branch ,fetch(:branch, 'staging')
set :stage, :staging
set :rails_env, :staging
server "46.101.90.1",
  user: "deploy",
  roles: %w{app db web}