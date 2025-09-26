# frozen_string_literal: true

require_relative 'my_activities'
require_relative 'my_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
keyword_args[:logger] = Logger.new($stdout, level: Logger::INFO)

# Create a Temporal client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

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
