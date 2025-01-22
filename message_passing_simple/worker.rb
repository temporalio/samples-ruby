# frozen_string_literal: true

require_relative 'call_greeting_service'
require_relative 'greeting_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'message-passing-simple-sample',
  activities: [MessagePassingSimple::CallGreetingService],
  workflows: [MessagePassingSimple::GreetingWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
