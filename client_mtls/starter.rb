# frozen_string_literal: true

require_relative 'greeting_workflow'
require 'optparse'
require 'temporalio/client'

# Define options parser to handle certificate paths and other parameters
options = {
  target_host: 'localhost:7233',
  namespace: 'default',
  task_queue: 'mtls-task-queue',
  server_root_ca_cert: nil,
  client_cert: nil,
  client_key: nil
}

OptionParser.new do |opts|
  opts.banner = 'Usage: starter.rb [options]'

  opts.on('--target-host HOST', 'Host:port for the server (default: localhost:7233)') do |v|
    options[:target_host] = v
  end

  opts.on('--namespace NAMESPACE', 'Namespace to use (default: default)') do |v|
    options[:namespace] = v
  end

  opts.on('--task-queue QUEUE', 'Task queue to use (default: mtls-task-queue)') do |v|
    options[:task_queue] = v
  end

  opts.on('--server-root-ca-cert PATH', 'Path to the server root CA certificate') do |v|
    options[:server_root_ca_cert] = v
  end

  opts.on('--client-cert PATH', 'Path to the client certificate (required for mTLS)') do |v|
    options[:client_cert] = v
  end

  opts.on('--client-key PATH', 'Path to the client key (required for mTLS)') do |v|
    options[:client_key] = v
  end
end.parse!

# Check for required certificates for mTLS
unless options[:client_cert] && options[:client_key]
  puts 'Error: Client certificate and key are required for mTLS'
  puts 'Usage: ruby starter.rb --client-cert PATH --client-key PATH'
  exit 1
end

puts "Connecting to Temporal Server at #{options[:target_host]} with mTLS..."
puts "Using namespace: #{options[:namespace]}"

# Connect to Temporal server
client = Temporalio::Client.connect(
  options[:target_host],
  options[:namespace],
  tls: Temporalio::Client::Connection::TLSOptions.new(
    client_cert: File.read(options[:client_cert]),
    client_private_key: File.read(options[:client_key]),
    server_root_ca_cert: options[:server_root_ca_cert] && File.read(options[:server_root_ca_cert])
  )
)

# Execute the workflow
puts 'Starting workflow with mTLS...'
handle = client.start_workflow(
  ClientMtls::GreetingWorkflow,
  'World',
  id: "mtls-workflow-#{Time.now.to_i}",
  task_queue: options[:task_queue]
)

puts "Started workflow. WorkflowID: #{handle.id}"

# Wait for workflow completion
result = handle.result
puts "Workflow completed with result: #{result}"
