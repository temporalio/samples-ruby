# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require 'temporalio/worker'
require_relative 'eager_workflow'
require_relative 'greeting_activity'

TASK_QUEUE = 'eager-wf-start-sample'

# Note that the worker and client run in the same process and share the same client connection
client = Temporalio::Client.connect('localhost:7233', 'default')

worker = Temporalio::Worker.new(
  client:,
  task_queue: TASK_QUEUE,
  workflows: [EagerWfStart::EagerWorkflow],
  activities: [EagerWfStart::GreetingActivity]
)

# Run worker in the background while we start the workflow
worker.run do
  handle = client.start_workflow(
    EagerWfStart::EagerWorkflow,
    'Temporal',
    id: 'eager-workflow-start-sample-workflow-id',
    task_queue: TASK_QUEUE,
    request_eager_start: true
  )

  puts handle.result
end
