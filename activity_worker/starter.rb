# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run workflow
result = client.execute_workflow(
  'SayHelloWorkflow',
  'SomeUser',
  id: 'activity-worker-sample-workflow-id',
  task_queue: 'activity-worker-sample'
)
puts "Workflow result: #{result}"
