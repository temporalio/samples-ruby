# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'saga_workflow'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
# Enable info logging to see our activity logs
logger = Logger.new($stdout, level: Logger::INFO)

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs, logger:)

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
