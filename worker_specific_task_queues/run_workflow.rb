# frozen_string_literal: true

require_relative 'file_processing_workflow'
require 'logger'
require 'temporalio/client'

# Create client with logger
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

# Run workflow
client.execute_workflow(
  WorkerSpecificTaskQueues::FileProcessingWorkflow,
  3, # max_attempts
  id: 'file-processing-workflow',
  task_queue: 'worker-specific-task-queues-sample'
)

puts 'Workflow completed successfully'
