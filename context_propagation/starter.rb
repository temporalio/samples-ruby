# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require_relative 'interceptor'
require_relative 'say_hello_workflow'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO),
  # Add the context propagation interceptor to propagate the :my_user
  # thread/fiber local
  interceptors: [ContextPropagation::Interceptor.new(:my_user)]
)

# Set user as "Alice" which will get propagated in a distributed way through
# the workflow and activity via Temporal headers
Thread.current[:my_user] = 'Alice'

# Start workflow, send signal, wait for completion, issue query
puts 'Executing workflow with user "Alice"'
handle = client.start_workflow(
  ContextPropagation::SayHelloWorkflow,
  'Bob',
  id: 'context-propagation-sample-workflow-id',
  task_queue: 'context-propagation-sample'
)
handle.signal(ContextPropagation::SayHelloWorkflow.signal_complete)
result = handle.result
_is_complete = handle.query(ContextPropagation::SayHelloWorkflow.complete?)
puts "Workflow result: #{result}"
