# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'my_activities'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

client = Temporalio::Client.connect(*args, **kwargs)

# Start a Standalone Activity without waiting for the result. The call returns
# as soon as the Activity is durably enqueued on the Server.
handle = client.start_activity(
  StandaloneActivity::MyActivities::ComposeGreeting,
  'Hello', 'World',
  id: 'standalone-activity-id',
  task_queue: 'standalone-activity-sample',
  start_to_close_timeout: 10
)
puts "Started Activity with id=#{handle.id} run_id=#{handle.run_id}"

# Wait for the result later via the handle.
puts "Activity result: #{handle.result}"
