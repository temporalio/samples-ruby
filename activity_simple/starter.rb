# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'my_workflow'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  ActivitySimple::MyWorkflow,
  id: 'activity-simple-sample-workflow-id',
  task_queue: 'activity-simple-sample'
)
puts "Workflow result: #{result}"
