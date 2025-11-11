# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'updatable_timer_workflow'

# Create a Temporal client
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
logger = Logger.new($stdout, level: Logger::INFO)
keyword_args[:logger] = logger
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run workflow
logger.info('Starting workflow')
client.execute_workflow(
  UpdatableTimer::UpdatableTimerWorkflow, (Time.now(in: 'utc') + (24 * 60 * 60)).to_r,
  id: 'updatable-timer-sample-workflow-id', task_queue: 'updatable-timer-sample'
)
logger.info('Workflow complete')
