# frozen_string_literal: true

require_relative 'updatable_timer_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Create a Temporal client
positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
positional_args = ['localhost:7233', 'default'] if positional_args.empty?
client = Temporalio::Client.connect(*positional_args, **keyword_args)

# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'updatable-timer-sample',
  workflows: [UpdatableTimer::UpdatableTimerWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
