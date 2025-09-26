# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'greeting_workflow'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  Polling::Infrequent::GreetingWorkflow,
  'World',
  id: "infrequent-polling-sample-workflow-id-#{Time.now.to_i}",
  task_queue: 'infrequent-polling-sample'
)
puts "Workflow result: #{result}"
