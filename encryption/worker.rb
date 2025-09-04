# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/worker'
require_relative 'codec'
require_relative 'my_workflow'

# Create a client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  # Set data converter with our codec
  data_converter: Temporalio::Converters::DataConverter.new(payload_codec: Encryption::Codec.new)
)

# Create worker with the workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'encryption-sample',
  workflows: [Encryption::MyWorkflow],
  # When using a payload codec in a non-fiber situation, Temporal requires a thread pool be set
  workflow_payload_codec_thread_pool: Temporalio::Worker::ThreadPool.default
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
