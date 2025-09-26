# frozen_string_literal: true

require 'logger'
require 'sorbet-runtime'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'say_hello_activity'
require_relative 'say_hello_workflow'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
keyword_args[:logger] = Logger.new($stdout, level: Logger::INFO)

# Create a Temporal client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'sorbet-typing-sample',
  activities: [SorbetGeneric::SayHelloActivity],
  workflows: [SorbetGeneric::SayHelloWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
