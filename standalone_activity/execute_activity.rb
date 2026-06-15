# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'my_activities'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

client = Temporalio::Client.connect(*args, **kwargs)

# Execute a Standalone Activity directly from the Client and block until it
# returns a result. The Activity is durably enqueued on the Server and run by
# the Worker registered for the same Task Queue.
result = client.execute_activity(
  StandaloneActivity::MyActivities::ComposeGreeting,
  'Hello', 'World',
  id: 'standalone-activity-id',
  task_queue: 'standalone-activity-sample',
  start_to_close_timeout: 10
)
puts "Activity result: #{result}"
