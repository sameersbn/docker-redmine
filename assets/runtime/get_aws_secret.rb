#!/usr/bin/env ruby

require 'aws-sdk-secretsmanager'

# Secret name in AWS Secrets Manager
secret_name = ARGV[0]
region_name = ARGV[1]

raise "Usage: #{__FILE__} <secret_name> <region_name>" unless ARGV[0] && ARGV[1]

# Retrieve credentials from Secrets Manager
begin
  client = Aws::SecretsManager::Client.new(region: region_name)
  secret_value = client.get_secret_value(secret_id: secret_name)

  # Extract the credentials
  puts secret_value.secret_string
rescue Aws::SecretsManager::Errors::ServiceError => e
  puts "Error accessing Secrets Manager: #{e.message}"
  exit 1
end
