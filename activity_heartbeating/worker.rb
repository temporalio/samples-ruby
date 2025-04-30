# frozen_string_literal: true

require_relative 'my_activities'
require_relative 'my_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'activity-heartbeating-sample',
  activities: [ActivityHeartbeating::MyActivities::FakeProgress],
  workflows: [ActivityHeartbeating::MyWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
