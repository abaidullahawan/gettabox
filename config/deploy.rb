# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock '~> 3.16.0'

set :application, 'channeldispatch'
set :repo_url, 'git@github.com:abaidullahawan/gettabox.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deploy/#{fetch :application}"
set :branch, 'main'
# Default value for :format is :airbrussh.
# set :format, :airbrussh
set :pty, false
set sidekiq_config: 'config/sidekiq.yml'
# SSHKit.config.command_map[:sidekiq]    = 'bundle exec sidekiq'
# SSHKit.config.command_map[:sidekiqctl] = 'bundle exec sidekiqctl'
# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system',
       'public/uploads', 'node_modules'
# set :user, "deploy"
# Rake::Task["sidekiq:stop"].clear_actions
# Rake::Task["sidekiq:start"].clear_actions
# Rake::Task["sidekiq:restart"].clear_actions
# namespace :sidekiq do
#   task :stop do
#     on roles(:app) do
#       execute :sudo, :systemctl, :stop, :sidekiq
#     end
#   end
#   task :start do
#     on roles(:app) do
#       execute :sudo, :systemctl, :start, :sidekiq
#     end
#   end
#   task :restart do
#     on roles(:app) do
#       execute :sudo, :systemctl, :restart, :sidekiq
#     end
#   end
# end
# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Optionally, you can symlink your database.yml and/or secrets.yml file from the shared directory during deploy
# This is useful if you don't want to use ENV variables
append :linked_files, 'config/database.yml', 'config/secrets.yml'
