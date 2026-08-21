# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'subscription_workflow'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a client
client = Temporalio::Client.connect(*args, **kwargs)

# Run workflow
puts 'Executing workflow'
client.start_workflow(
  Timer::SubscriptionWorkflow,
  'user-id-123',
  id: 'timer-sample-workflow-id',
  task_queue: 'timer-sample'
)
puts 'Workflow started (cancel it from the UI or CLI to see cancellation handling)'
