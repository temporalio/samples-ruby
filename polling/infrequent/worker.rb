# frozen_string_literal: true

require_relative 'greeting_workflow'
require_relative 'compose_greeting_activity'
require 'temporalio/client'
require 'temporalio/worker'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

worker = Temporalio::Worker.new(
  client:,
  task_queue: 'infrequent-polling-sample',
  workflows: [InfrequentPolling::GreetingWorkflow],
  activities: [InfrequentPolling::ComposeGreetingActivity]
)

puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
