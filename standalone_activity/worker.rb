# frozen_string_literal: true

require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'my_activities'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# A Worker for Standalone Activities is configured the same way as one for
# Workflow Activities: register the Activity classes and run the Worker. No
# Workflows are required.
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'standalone-activity-sample',
  activities: [StandaloneActivity::MyActivities::ComposeGreeting]
)

puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
