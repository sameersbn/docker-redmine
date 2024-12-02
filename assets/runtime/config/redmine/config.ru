# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  run Rails.application
end
