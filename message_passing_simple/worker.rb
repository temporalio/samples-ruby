# frozen_string_literal: true

require_relative 'call_greeting_service'
require_relative 'greeting_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

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
