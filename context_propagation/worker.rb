# frozen_string_literal: true

require_relative 'interceptor'
require_relative 'say_hello_activity'
require_relative 'say_hello_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
keyword_args[:logger] = Logger.new($stdout, level: Logger::INFO)
# Add the context propagation interceptor to propagate the :my_user thread/fiber local
keyword_args[:interceptors] = [ContextPropagation::Interceptor.new(:my_user)]

# Create a Temporal client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'context-propagation-sample',
  activities: [ContextPropagation::SayHelloActivity],
  workflows: [ContextPropagation::SayHelloWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
