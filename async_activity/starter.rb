# frozen_string_literal: true

require 'temporalio/client'
require_relative 'my_workflow'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  AsyncActivity::MyWorkflow,
  id: 'activity-simple-sample-workflow-id',
  task_queue: 'activity-simple-sample'
)
puts "Workflow result: #{result}"
