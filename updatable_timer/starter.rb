# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'updatable_timer_workflow'

# Create a Temporal client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
logger = Logger.new($stdout, level: Logger::INFO)
client = Temporalio::Client.connect(*args, **kwargs, logger:)

# Run workflow
logger.info('Starting workflow')
client.execute_workflow(
  UpdatableTimer::UpdatableTimerWorkflow, (Time.now(in: 'utc') + (24 * 60 * 60)).to_r,
  id: 'updatable-timer-sample-workflow-id', task_queue: 'updatable-timer-sample'
)
logger.info('Workflow complete')
