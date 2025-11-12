# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'greeting_workflow'

# Create a client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs)

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  Polling::Frequent::GreetingWorkflow,
  'World',
  id: "frequent-polling-sample-workflow-id-#{Time.now.to_i}",
  task_queue: 'frequent-polling-sample'
)
puts "Workflow result: #{result}"
