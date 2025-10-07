# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

def main
  puts "--- Loading 'staging' profile with programmatic overrides ---"

  config_file = File.join(__dir__, 'config.toml')
  profile_name = 'staging'

  puts "The 'staging' profile in config.toml has an incorrect address (localhost:9999)."
  puts "We'll programmatically override it to the correct address."

  # Load the 'staging' profile.
  args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options(
    profile: profile_name,
    config_source: Pathname.new(config_file)
  )

  # Override the target host to the correct address.
  # This is the recommended way to override configuration values.
  args[0] = 'localhost:7233'

  puts "\nLoaded '#{profile_name}' profile from #{config_file} with overrides."
  puts "  Address: #{args[0]} (overridden from localhost:9999)"
  puts "  Namespace: #{args[1]}"

  puts "\nAttempting to connect to client..."
  begin
    client = Temporalio::Client.connect(*args, **kwargs)
    puts '✅ Client connected successfully!'
    sys_info = client.workflow_service.get_system_info(Temporalio::Api::WorkflowService::V1::GetSystemInfoRequest.new)
    puts "✅ Successfully verified connection to Temporal server!\n#{sys_info}"
  rescue StandardError => e
    puts "❌ Failed to connect: #{e}"
  end
end

main if $PROGRAM_NAME == __FILE__
