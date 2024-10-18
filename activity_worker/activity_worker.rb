# frozen_string_literal: true

require_relative 'activity'
require 'temporalio/client'
require 'temporalio/worker'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Create worker with the client and activity
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'activity-worker-sample',
  # By providing the class to the activity, it will be instantiated for every
  # attempt. If we provide an instance (e.g. SayHelloActivity.new), the same
  # instance is reused.
  activities: [ActivityWorker::SayHelloActivity]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
