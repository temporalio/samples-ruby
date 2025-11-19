# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'dsl_workflow'

# Create a Temporal client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

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
