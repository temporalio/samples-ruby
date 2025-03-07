# frozen_string_literal: true

require 'logger'
require 'sorbet-runtime'
require 'temporalio/client'
require 'temporalio/worker'
require_relative 'say_hello_activity'
require_relative 'say_hello_workflow'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

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
