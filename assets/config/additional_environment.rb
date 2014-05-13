config.gem 'dalli'
config.action_controller.perform_caching  = {{ENABLE_CACHE}}
config.cache_classes = true
config.cache_store = :dalli_store, "127.0.0.1:11211"
