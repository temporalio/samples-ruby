# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require_relative 'dsl_workflow'
require_relative 'activities'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client: client,
  task_queue: 'dsl-workflow-sample',
  activities: [
    Dsl::Activities::Activity1,
    Dsl::Activities::Activity2,
    Dsl::Activities::Activity3,
    Dsl::Activities::Activity4,
    Dsl::Activities::Activity5
  ],
  workflows: [Dsl::DslWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
