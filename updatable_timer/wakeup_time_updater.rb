# frozen_string_literal: true

require 'temporalio/client'
require_relative 'updatable_timer_workflow'

# Create a Temporal client
logger = Logger.new($stdout, level: Logger::INFO)
client = Temporalio::Client.connect('localhost:7233', 'default', logger:)
handle = client.workflow_handle('updatable-timer-sample-workflow-id')

handle.signal(UpdatableTimer::UpdatableTimerWorkflow.update_wake_up_time, (Time.now(in: 'utc') + 10).to_r)
logger.info('Updated wake up time to 10 seconds from now')
