# frozen_string_literal: true

require 'temporalio/client'
require_relative 'codec'
require_relative 'my_workflow'

# Create a client
client = Temporalio::Client.connect(
  'localhost:7233', 'default',
  # Set data converter with our codec
  data_converter: Temporalio::Converters::DataConverter.new(payload_codec: Encryption::Codec.new)
)

# Run workflow
puts 'Executing workflow'
result = client.execute_workflow(
  Encryption::MyWorkflow,
  'Temporal', # workflow argument
  id: 'encryption-sample-workflow-id',
  task_queue: 'encryption-sample'
)
puts "Workflow result: #{result}"
