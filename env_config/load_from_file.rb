# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

def main
  puts '--- Loading default profile from config.toml ---'

  # For this sample to be self-contained, we explicitly provide the path to
  # the config.toml file included in this directory.
  # By default though, the config.toml file will be loaded from
  # ~/.config/temporalio/temporal.toml (or the equivalent standard config directory on your OS).
  config_file = File.join(__dir__, 'config.toml')

  # load_client_connect_options is a helper that loads a profile and prepares
  # the configuration for Client.connect. By default, it loads the
  # "default" profile.
  args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options(
    config_source: Pathname.new(config_file)
  )

  puts "Loaded 'default' profile from #{config_file}."
  puts "  Address: #{args[0]}"
  puts "  Namespace: #{args[1]}"
  puts "  gRPC Metadata: #{kwargs[:rpc_metadata]}"

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
