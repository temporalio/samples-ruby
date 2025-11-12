# frozen_string_literal: true

require_relative 'my_activities'
require_relative 'my_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Use an instance for the stateful DB activity, other activity we will pass
# in as class meaning it is instantiated each attempt
db_client = ActivitySimple::MyActivities::MyDatabaseClient.new
select_from_db_activity = ActivitySimple::MyActivities::SelectFromDatabase.new(db_client)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'activity-simple-sample',
  activities: [select_from_db_activity, ActivitySimple::MyActivities::AppendSuffix],
  workflows: [ActivitySimple::MyWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
