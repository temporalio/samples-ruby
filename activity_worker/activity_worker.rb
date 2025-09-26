# frozen_string_literal: true

require_relative 'say_hello_activity'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

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
