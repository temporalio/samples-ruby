# frozen_string_literal: true

require 'temporalio/client'
require_relative 'greeting_workflow'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Start the workflow
puts 'Starting workflow'
handle = client.start_workflow(
  MessagePassingSimple::GreetingWorkflow,
  id: 'message-passing-simple-sample-workflow-id',
  task_queue: 'message-passing-simple-sample'
)

# Send a query
supported_languages = handle.query(MessagePassingSimple::GreetingWorkflow.languages, { include_unsupported: false })
puts "Supported languages: #{supported_languages}"

# Execute an update
prev_language = handle.execute_update(MessagePassingSimple::GreetingWorkflow.set_language, :chinese)
curr_language = handle.query(MessagePassingSimple::GreetingWorkflow.language)
puts "Language changed: #{prev_language} -> #{curr_language}"

# Start an update and then wait for it to complete
update_handle = handle.start_update(
  MessagePassingSimple::GreetingWorkflow.apply_language_with_lookup,
  :arabic,
  wait_for_stage: Temporalio::Client::WorkflowUpdateWaitStage::ACCEPTED
)
prev_language = update_handle.result
curr_language = handle.query(MessagePassingSimple::GreetingWorkflow.language)
puts "Language changed: #{prev_language} -> #{curr_language}"

# Send signal and wait for workflow to complete
handle.signal(MessagePassingSimple::GreetingWorkflow.approve, { name: 'John Q. Approver' })
puts "Workflow result: #{handle.result}"
