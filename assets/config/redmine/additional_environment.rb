config.gem 'dalli'
config.action_controller.perform_caching  = true
config.cache_classes = true
config.cache_store = :dalli_store, "{{MEMCACHE_HOST}}:{{MEMCACHE_PORT}}"
