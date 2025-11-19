# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'codec'
require_relative 'my_workflow'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
# Set data converter with our codec
data_converter = Temporalio::Converters::DataConverter.new(payload_codec: Encryption::Codec.new)

# Create a client
client = Temporalio::Client.connect(*args, **kwargs, data_converter: data_converter)

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  Encryption::MyWorkflow,
  'Temporal', # workflow argument
  id: 'encryption-sample-workflow-id',
  task_queue: 'encryption-sample'
)
puts "Workflow result: #{result}"
