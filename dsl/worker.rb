# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'dsl_workflow'

# Create a Temporal client
logger = Logger.new($stdout, level: Logger::INFO)
client = Temporalio::Client.connect('localhost:7233', 'default', logger:)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'dsl-sample',
  activities: [Dsl::Activities::Activity1, Dsl::Activities::Activity2, Dsl::Activities::Activity3,
               Dsl::Activities::Activity4, Dsl::Activities::Activity5],
  workflows: [Dsl::DslWorkflow]
)

# Run the worker until SIGINT
logger.info('Starting worker (ctrl+c to exit)')
worker.run(shutdown_signals: ['SIGINT'])
