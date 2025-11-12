# frozen_string_literal: true

require_relative 'my_activities'
require_relative 'workflow_1_initial'
require_relative 'workflow_2_patched'
require_relative 'workflow_3_deprecated'
require_relative 'workflow_4_complete'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'

# Create a Temporal client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

workflow_versions = {
  'initial' => Patching::MyWorkflow1Initial,
  'patched' => Patching::MyWorkflow2Patched,
  'deprecated' => Patching::MyWorkflow3Deprecated,
  'complete' => Patching::MyWorkflow4Complete
}

# Select which version of the workflow the worker should use
workflow_version = ARGV.first || raise('Missing argument for workflow version')
workflow = workflow_versions[workflow_version] ||
           raise("Unrecognized workflow #{workflow_version}. Accepted values are #{workflow_versions.keys.join(', ')}")
# Create worker with the activities and workflow
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'patching-sample',
  activities: [Patching::MyActivities::PrePatch, Patching::MyActivities::PostPatch],
  workflows: [
    workflow
  ]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
