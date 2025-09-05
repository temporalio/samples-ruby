# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'saga_workflow'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233', 'default',
  # Enable info logging to see our activity logs
  logger: Logger.new($stdout, level: Logger::INFO)
)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'saga-sample',
  activities: [Saga::Activities::Withdraw, Saga::Activities::WithdrawCompensation,
               Saga::Activities::Deposit, Saga::Activities::DepositCompensation,
               Saga::Activities::SomethingThatFails],
  workflows: [Saga::SagaWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
