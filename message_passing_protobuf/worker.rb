# frozen_string_literal: true

require_relative 'call_greeting_service'
require_relative 'greeting_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create custom data converter with BinaryProtobuf before JSONProtobuf for UTF-8 support
payload_converter = Temporalio::Converters::PayloadConverter::Composite.new(
  Temporalio::Converters::PayloadConverter::BinaryNull.new,
  Temporalio::Converters::PayloadConverter::BinaryPlain.new,
  Temporalio::Converters::PayloadConverter::BinaryProtobuf.new,  # Binary first for UTF-8 support
  Temporalio::Converters::PayloadConverter::JSONProtobuf.new,
  Temporalio::Converters::PayloadConverter::JSONPlain.new
)
data_converter = Temporalio::Converters::DataConverter.new(payload_converter: payload_converter)

# Create a client
client = Temporalio::Client.connect(*args, **kwargs, data_converter: data_converter)

# Create worker with the activity and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'message-passing-simple-sample',
  activities: [MessagePassingProtobuf::GetGreetings],
  workflows: [MessagePassingProtobuf::GreetingWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
