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
db_client = AsyncActivity::MyActivities::MyDatabaseClient.new
select_from_db_activity = AsyncActivity::MyActivities::SelectFromDatabase.new(db_client)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'apps',
  activities: [select_from_db_activity, AsyncActivity::MyActivities::AppendSuffix, AsyncActivity::MyActivities::ExecuteAsyncOperation],
  workflows: [AsyncActivity::MyWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
