# frozen_string_literal: true

require_relative 'file_processing_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create client with logger
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Run workflow
client.execute_workflow(
  WorkerSpecificTaskQueues::FileProcessingWorkflow,
  3, # max_attempts
  id: 'file-processing-workflow',
  task_queue: 'worker-specific-task-queues-sample'
)

puts 'Workflow completed successfully'
