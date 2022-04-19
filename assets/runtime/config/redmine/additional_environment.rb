config.gem 'dalli'
config.action_controller.perform_caching  = true
config.cache_classes = true
config.cache_store = :mem_cache_store, "{{MEMCACHE_HOST}}:{{MEMCACHE_PORT}}"
