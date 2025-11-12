# frozen_string_literal: true

require_relative 'file_processing_workflow'
require_relative 'normal_activities'
require_relative 'worker_specific_activities'
require 'logger'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create client with logger
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Create a unique task queue for this worker
unique_task_queue = SecureRandom.uuid

# Create worker for shared task queue
shared_worker = Temporalio::Worker.new(
  client: client,
  task_queue: 'worker-specific-task-queues-sample',
  workflows: [WorkerSpecificTaskQueues::FileProcessingWorkflow],
  activities: [
    # Pass the unique task queue to the activity so it can return it when called
    WorkerSpecificTaskQueues::NormalActivities::GetUniqueTaskQueueActivity.new(unique_task_queue)
  ]
)

# Create worker for unique task queue
unique_worker = Temporalio::Worker.new(
  client: client,
  task_queue: unique_task_queue,
  activities: [
    WorkerSpecificTaskQueues::WorkerSpecificActivities::DownloadFileActivity.new,
    WorkerSpecificTaskQueues::WorkerSpecificActivities::WorkOnFileActivity.new,
    WorkerSpecificTaskQueues::WorkerSpecificActivities::CleanupFileActivity.new
  ]
)

puts "Running worker with unique task queue: #{unique_task_queue}"

# Run both workers using run_all for concurrent execution
# The workers need to be passed as separate arguments, not as an array
Temporalio::Worker.run_all(shared_worker, unique_worker, shutdown_signals: ['SIGINT'])
