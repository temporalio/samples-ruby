# frozen_string_literal: true

require 'securerandom'
require 'temporalio/client'
require_relative 'dsl_workflow'
require_relative 'dsl_models'

# Ensure workflow file is provided
if ARGV.empty?
  puts 'Please provide a workflow YAML file'
  puts 'Usage: ruby starter.rb workflow_file.yaml'
  exit 1
end

file_path = ARGV[0]
unless File.exist?(file_path)
  puts "File not found: #{file_path}"
  exit 1
end

# Read the YAML workflow
yaml_content = File.read(file_path)

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Generate a unique workflow ID
workflow_id = "dsl-workflow-#{SecureRandom.uuid}"

puts "Executing workflow: #{workflow_id}"
puts "Using workflow definition from: #{file_path}"

# Execute the workflow with the YAML content directly
result = client.execute_workflow(
  Dsl::DslWorkflow,
  yaml_content,
  id: workflow_id,
  task_queue: 'dsl-workflow-sample'
)

# Display final variables
puts "\nWorkflow completed. Final variables:"
result.each do |key, value|
  puts "  #{key}: #{value}"
end
