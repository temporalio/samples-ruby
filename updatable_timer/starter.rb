# frozen_string_literal: true

require 'temporalio/client'
require_relative 'updatable_timer_workflow'

# Create a Temporal client
logger = Logger.new($stdout, level: Logger::INFO)
client = Temporalio::Client.connect('localhost:7233', 'default', logger:)

# Run workflow
logger.info('Starting timer')
client.execute_workflow(
  UpdatableTimer::UpdatableTimerWorkflow, (Time.now(in: 'utc') + (24 * 60 * 60)).to_r,
  id: 'updatable-timer-sample-workflow-id', task_queue: 'updatable-timer'
)
logger.info('Timer complete')
