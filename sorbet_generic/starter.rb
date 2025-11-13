# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'
require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'say_hello_workflow'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a client
client = Temporalio::Client.connect(*args, **kwargs)

# Start workflow
handle = client.start_workflow(
  SorbetGeneric::SayHelloWorkflow,
  id: 'sorbet-typing-sample-workflow-id',
  task_queue: 'sorbet-typing-sample'
)
# T.reveal_type(handle) # The result is a handle with the String result type
puts "Started workflow with ID #{handle.id} and run ID #{handle.result_run_id}"

# Send an update
update_result = handle.execute_update(
  # If this is not an update definition or if the parameter is not a string, this fails type check
  SorbetGeneric::SayHelloWorkflow.say_hello,
  'some-user'
)
# T.reveal_type(update_result) # The result is properly typed as a String
puts "Workflow update result: #{update_result}"

# Send a signal telling the workflow to complete
handle.signal(
  # If this is not a signal definition or if the parameter is not a string, this fails type check
  SorbetGeneric::SayHelloWorkflow.complete,
  'some-result'
)

# Get workflow result
result = handle.result
# T.reveal_type(result) # The result is properly typed as a String
puts "Workflow result: #{result}"

# Issue query for the "completed" boolean
query_result = handle.query(
  # If this is not a query definition, this fails type check
  SorbetGeneric::SayHelloWorkflow.completed
)
# T.reveal_type(query_result) # The result is properly typed as a nilable Boolean
puts "Workflow query result: #{query_result}"
