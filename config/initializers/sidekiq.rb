# Sidekiq.configure_server do |config|
#   config.redis = { url: 'redis://localhost:6379/0' }
# end
# Sidekiq.configure_client do |config|
#   config.redis = { url: 'redis://localhost:6379/0' }
# end
if defined? Sidekiq
  redis_url = ENV['REDIS_URL']

  Sidekiq.configure_server do |config|
    config.redis = {
      url: redis_url,
      namespace: 'workers',
      size: 15
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: redis_url,
      namespace: 'workers',
      size: 2
    }
  end
end
