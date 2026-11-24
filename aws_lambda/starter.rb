# frozen_string_literal: true

require 'pathname'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/versioning_override'
require 'temporalio/worker_deployment_version'

# Match the handler's TOML lookup, including when run outside Lambda.
path = ENV.fetch('TEMPORAL_CONFIG_FILE', nil)
if path.nil? || path.empty?
  path = File.join(ENV.fetch('LAMBDA_TASK_ROOT', Dir.pwd), 'temporal.toml')
  path = nil unless File.file?(path)
end
config_options = path ? { config_source: Pathname.new(path) } : { disable_file: true }
args, options = Temporalio::EnvConfig::ClientConfig.load_client_connect_options(**config_options)
client = Temporalio::Client.connect(*args, **options)
version = Temporalio::WorkerDeploymentVersion.new(
  deployment_name: ENV.fetch('TEMPORAL_DEPLOYMENT_NAME'),
  build_id: ENV.fetch('TEMPORAL_WORKER_BUILD_ID')
)
puts client.execute_workflow(
  'LambdaGreetingWorkflow', 'Ruby',
  id: "lambda-greeting-#{SecureRandom.uuid}", task_queue: ENV.fetch('TEMPORAL_TASK_QUEUE'),
  versioning_override: Temporalio::VersioningOverride::Pinned.new(version)
)
