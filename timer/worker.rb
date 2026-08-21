# frozen_string_literal: true

require_relative 'subscription_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'timer-sample',
  activities: [Timer::MyActivities::Charge],
  workflows: [Timer::SubscriptionWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
