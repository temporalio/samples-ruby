# frozen_string_literal: true

require 'temporalio/client'
require_relative 'activities'
require_relative 'models'
require_relative 'dsl_workflow'

# Create a Temporal client
logger = Logger.new($stdout, level: Logger::INFO)
client = Temporalio::Client.connect('localhost:7233', 'default', logger:)

# Load YAML file
yaml_str = File.read(ARGV.first || raise('Missing argument for YAML file'))
input = Dsl::Models::Input.from_yaml(yaml_str)

# Run workflow
result = client.execute_workflow(
  Dsl::DslWorkflow, input,
  id: 'dsl-sample-workflow-id', task_queue: 'dsl-sample'
)
logger.info("Final variables: #{result}")
