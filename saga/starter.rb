# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require_relative 'activities'
require_relative 'saga_workflow'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create a Temporal client
client = Temporalio::Client.connect(*args, **kwargs)

# Run workflow that we know will fail
client.execute_workflow(
  Saga::SagaWorkflow,
  Saga::Activities::TransferDetails.new(
    amount: 100,
    from_account: 'acc1000',
    to_account: 'acc2000',
    reference_id: '1324'
  ),
  id: 'saga-sample-workflow-id',
  task_queue: 'saga-sample'
)
