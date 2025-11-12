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
  Polling::PeriodicSequence::GreetingWorkflow,
  'World',
  id: "periodic-sequence-polling-sample-workflow-id-#{Time.now.to_i}",
  task_queue: 'periodic-sequence-polling-sample'
)
puts "Workflow result: #{result}"
