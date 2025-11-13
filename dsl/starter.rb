# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'activities'
require_relative 'models'
require_relative 'dsl_workflow'

# Create a Temporal client
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace
client = Temporalio::Client.connect(*args, **kwargs, logger: Logger.new($stdout, level: Logger::INFO))

# Load YAML file
yaml_str = File.read(ARGV.first || raise('Missing argument for YAML file'))
input = Dsl::Models::Input.from_yaml(yaml_str)

# Run workflow
result = client.execute_workflow(
  Dsl::DslWorkflow, input,
  id: 'dsl-sample-workflow-id', task_queue: 'dsl-sample'
)
logger.info("Final variables: #{result}")
