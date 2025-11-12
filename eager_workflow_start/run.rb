# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'eager_workflow'
require_relative 'greeting_activity'

TASK_QUEUE = 'eager-workflow-start-sample'

# Note that the worker and client run in the same process and share the same client connection
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs)

worker = Temporalio::Worker.new(
  client:,
  task_queue: TASK_QUEUE,
  workflows: [EagerWorkflowStart::EagerWorkflow],
  activities: [EagerWorkflowStart::GreetingActivity]
)

# Run worker in the background while we start the workflow
worker.run do
  handle = client.start_workflow(
    EagerWorkflowStart::EagerWorkflow,
    'Temporal',
    id: 'eager-workflow-start-sample-workflow-id',
    task_queue: TASK_QUEUE,
    request_eager_start: true
  )

  puts handle.result
end
