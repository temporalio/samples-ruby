# frozen_string_literal: true

require_relative 'greeting_workflow'
require_relative 'compose_greeting_activity'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

worker = Temporalio::Worker.new(
  client:,
  task_queue: 'infrequent-polling-sample',
  workflows: [Polling::Infrequent::GreetingWorkflow],
  activities: [Polling::Infrequent::ComposeGreetingActivity]
)

puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
