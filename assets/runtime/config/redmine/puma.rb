#Change to match your CPU core count
# Check using this on the server => grep -c processor /proc/cpuinfo
workers {{PUMA_WORKERS}}
preload_app!

# Min and Max threads per worker
threads 1, 6
app_dir    = File.expand_path("{{REDMINE_INSTALL_DIR}}")

# Default to production
rails_env = ENV['RAILS_ENV'] || 'production'
environment rails_env

ENV['RAILS_RELATIVE_URL_ROOT'] = "{{REDMINE_RELATIVE_URL_ROOT}}"

# Set up socket location
bind "unix://#{app_dir}/tmp/sockets/puma.sock"
bind "tcp://0.0.0.0:8080"

# Logging
stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"
activate_control_app


before_fork do |server, worker|
  require 'active_record'
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

end

on_worker_boot do
  require 'active_record'

  # the following is *required* for Rails + "preload_app true",
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end