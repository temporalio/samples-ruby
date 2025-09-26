# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require_relative 'codec'
require_relative 'my_workflow'

# Load config and apply defaults
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
# Set data converter with our codec
keyword_args[:data_converter] = Temporalio::Converters::DataConverter.new(payload_codec: Encryption::Codec.new)

# Create a client
client = Temporalio::Client.connect(*positional_args, **keyword_args)

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
