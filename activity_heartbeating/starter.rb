# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'my_workflow'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

workflow_id = 'activity-heartbeating-workflow-id'
task_queue = 'activity-heartbeating-sample'

# Start workflow
puts 'Starting workflow'
handle = client.start_workflow(
  ActivityHeartbeating::MyWorkflow,
  id: workflow_id,
  task_queue: task_queue
)

puts "Workflow started with ID: #{workflow_id}"
puts 'Waiting 15 seconds before cancelling workflow...'

# Wait some time to let the activity make progress
sleep 15

# Cancel the workflow
puts 'Cancelling workflow...'
handle.cancel

begin
  # Wait for result (which will fail with cancellation)
  result = handle.result
  puts "Workflow completed with result: #{result}"
rescue Temporalio::Error::WorkflowFailedError => e
  raise unless e.cause.is_a?(Temporalio::Error::CanceledError)

  puts 'Workflow was successfully cancelled'
end
