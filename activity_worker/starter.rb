# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a client
client = Temporalio::Client.connect(*args, **kwargs)

# Run workflow
result = client.execute_workflow(
  'SayHelloWorkflow',
  'SomeUser',
  id: 'activity-worker-sample-workflow-id',
  task_queue: 'activity-worker-sample'
)
puts "Workflow result: #{result}"
