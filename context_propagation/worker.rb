# frozen_string_literal: true

require_relative 'interceptor'
require_relative 'say_hello_activity'
require_relative 'say_hello_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO),
  # Add the context propagation interceptor to propagate the :my_user thread/fiber local
  interceptors: [ContextPropagation::Interceptor.new(:my_user)]
)

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'context-propagation-sample',
  activities: [ContextPropagation::SayHelloActivity],
  workflows: [ContextPropagation::SayHelloWorkflow],
  workflow_executor: Temporalio::Worker::WorkflowExecutor::ThreadPool.default
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
