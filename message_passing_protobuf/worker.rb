# frozen_string_literal: true

require_relative 'call_greeting_service'
require_relative 'greeting_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a client
client = Temporalio::Client.connect(*args, **kwargs)

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'message-passing-simple-sample',
  activities: [MessagePassingProtobuf::GetGreetings],
  workflows: [MessagePassingProtobuf::GreetingWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
