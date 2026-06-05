# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

client = Temporalio::Client.connect(*args, **kwargs)

# Count Standalone Activity Executions matching a query. Only Standalone
# Activity Executions are counted -- Activities scheduled inside Workflows
# are not.
result = client.count_activities("TaskQueue = 'standalone-activity-sample'")
puts "Total: #{result.count}"
result.groups.each do |group|
  puts "  #{group.group_values.join(',')} => #{group.count}"
end
