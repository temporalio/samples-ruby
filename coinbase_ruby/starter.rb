# frozen_string_literal: true

# We must require Temporal SDK first and set the env var to prevent Coinbase SDK from trying to load its protos
require 'temporalio/client'
require 'temporalio/env_config'
ENV['COINBASE_TEMPORAL_RUBY_DISABLE_PROTO_LOAD'] = '1'

require_relative 'coinbase_workflow'
require_relative 'temporal_workflow'
require 'logger'
require 'temporal-ruby'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?

# Create Temporal SDK client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Run Coinbase workflow
result = client.execute_workflow(
  CoinbaseRuby::CoinbaseWorkflow.name, 'user1',
  id: 'coinbase-ruby-sample-workflow-id-1', task_queue: 'coinbase-ruby-sample-coinbase'
)
puts "Coinbase SDK workflow result from Temporal SDK client: #{result}"

# Run Temporal workflow
result = client.execute_workflow(
  CoinbaseRuby::TemporalWorkflow, 'user2',
  id: 'coinbase-ruby-sample-workflow-id-2', task_queue: 'coinbase-ruby-sample-temporal'
)
puts "Temporal SDK workflow result from Temporal SDK client: #{result}"

# Now do the same with Coinbase SDK, first configuring the client
Temporal.configure do |config|
  config.host = 'localhost'
  config.port = 7233
  config.namespace = 'default'
end

# Run Coinbase workflow
run_id = Temporal.start_workflow(
  CoinbaseRuby::CoinbaseWorkflow, 'user3',
  options: { workflow_id: 'coinbase-ruby-sample-workflow-id-3', task_queue: 'coinbase-ruby-sample-coinbase' }
)
result = Temporal.await_workflow_result(
  CoinbaseRuby::CoinbaseWorkflow,
  workflow_id: 'coinbase-ruby-sample-workflow-id-3', run_id:
)
puts "Coinbase SDK workflow result from Coinbase SDK client: #{result}"

# Run Temporal workflow
run_id = Temporal.start_workflow(
  :TemporalWorkflow, 'user4',
  options: { workflow_id: 'coinbase-ruby-sample-workflow-id-4', task_queue: 'coinbase-ruby-sample-temporal' }
)
result = Temporal.await_workflow_result(
  :TemporalWorkflow,
  workflow_id: 'coinbase-ruby-sample-workflow-id-4', run_id:
)
puts "Temporal SDK workflow result from Coinbase SDK client: #{result}"
