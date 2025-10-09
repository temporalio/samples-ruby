# frozen_string_literal: true

require 'temporalio/client'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

command, workflow_id = ARGV
raise('Missing command argument. Valid commands are start and query') if command.nil?
raise('Missing workflow_id') if workflow_id.nil?

case command
when 'start'
  # Start a workflow with the given id
  client.start_workflow(
    'MyWorkflow',
    id: workflow_id,
    task_queue: 'patching-sample'
  )
  puts "Started workflow with id #{workflow_id}"
when 'query'
  # Obtain a workflow handle for the given id and query the result
  handle = client.workflow_handle(workflow_id)
  result = handle.query(:result)
  puts "Query result for id #{workflow_id}: #{result}"
else
  raise('Invalid command. Valid commands are start and query')
end
