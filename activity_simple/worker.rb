# frozen_string_literal: true

require_relative 'my_activities'
require_relative 'my_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

# Use an instance for the stateful DB activity, other activity we will pass
# in as class meaning it is instantiated each attempt
db_client = ActivitySimple::MyActivities::MyDatabaseClient.new
select_from_db_activity = ActivitySimple::MyActivities::SelectFromDatabase.new(db_client)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'activity-simple-sample',
  activities: [select_from_db_activity, ActivitySimple::MyActivities::AppendSuffix],
  workflows: [ActivitySimple::MyWorkflow],
  workflow_executor: Temporalio::Worker::WorkflowExecutor::ThreadPool.default
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
