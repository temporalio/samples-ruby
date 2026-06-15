# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

client = Temporalio::Client.connect(*args, **kwargs)

# List Standalone Activity Executions on this Task Queue. Only Standalone
# Activity Executions are returned -- Activities scheduled inside Workflows
# are not.
client.list_activities("TaskQueue = 'standalone-activity-sample'").each do |execution|
  puts "#{execution.activity_id} #{execution.activity_type} #{execution.status}"
end
