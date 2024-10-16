# frozen_string_literal: true

require 'temporalio/client'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Run workflow
result = client.execute_workflow(
  'SayHelloWorkflow',
  'SomeUser',
  id: 'activity-worker-sample-workflow-id',
  task_queue: 'activity-worker-sample'
)
puts "Workflow result: #{result}"
