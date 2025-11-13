# frozen_string_literal: true

require_relative 'greeting_workflow'
require_relative 'compose_greeting_activity'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Create a client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs)

worker = Temporalio::Worker.new(
  client:,
  task_queue: 'frequent-polling-sample',
  workflows: [Polling::Frequent::GreetingWorkflow],
  activities: [Polling::Frequent::ComposeGreetingActivity]
)

puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
