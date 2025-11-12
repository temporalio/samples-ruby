# frozen_string_literal: true

# We must require Temporal SDK first and set the env var to prevent Coinbase SDK from trying to load its protos
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
ENV['COINBASE_TEMPORAL_RUBY_DISABLE_PROTO_LOAD'] = '1'

require_relative 'coinbase_activity'
require_relative 'coinbase_workflow'
require_relative 'temporal_activity'
require_relative 'temporal_workflow'
require 'logger'
require 'temporal-ruby'
require 'temporal/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Create Temporal worker with the activity and workflow on the coinbase-ruby-sample-temporal task queue
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'coinbase-ruby-sample-temporal',
  activities: [CoinbaseRuby::TemporalActivity],
  workflows: [CoinbaseRuby::TemporalWorkflow]
)

# Run the Temporal worker and inside it run the Coinbase worker
puts 'Starting worker on both Temporal Ruby SDK and Coinbase Ruby SDK'
worker.run do
  # Configure Coinbase client/worker on the coinbase-ruby-sample-coinbase task queue
  Temporal.configure do |config|
    config.host = 'localhost'
    config.port = 7233
    config.namespace = 'default'
    config.task_queue = 'coinbase-ruby-sample-coinbase'
  end

  # Run the Coinbase worker
  worker = Temporal::Worker.new
  worker.register_activity(CoinbaseRuby::CoinbaseActivity)
  worker.register_workflow(CoinbaseRuby::CoinbaseWorkflow)
  worker.start
end
