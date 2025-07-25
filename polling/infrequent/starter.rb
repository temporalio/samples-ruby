# frozen_string_literal: true

require 'temporalio/client'
require_relative 'greeting_workflow'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  InfrequentPolling::GreetingWorkflow,
  'World',
  id: "infrequent-polling-sample-workflow-id-#{Time.now.to_i}",
  task_queue: 'infrequent-polling-sample'
)
puts "Workflow result: #{result}"
