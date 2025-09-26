# frozen_string_literal: true

require_relative 'file_processing_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
keyword_args[:logger] = Logger.new($stdout, level: Logger::INFO)

# Create client with logger
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run workflow
client.execute_workflow(
  WorkerSpecificTaskQueues::FileProcessingWorkflow,
  3, # max_attempts
  id: 'file-processing-workflow',
  task_queue: 'worker-specific-task-queues-sample'
)

puts 'Workflow completed successfully'
