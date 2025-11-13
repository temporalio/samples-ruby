# frozen_string_literal: true

require_relative 'interceptor'
require_relative 'say_hello_activity'
require_relative 'say_hello_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
# Add the context propagation interceptor to propagate the :my_user thread/fiber local
interceptors = [ContextPropagation::Interceptor.new(:my_user)]

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO),
                                                     interceptors: interceptors)

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
