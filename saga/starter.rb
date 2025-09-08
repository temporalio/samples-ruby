# frozen_string_literal: true

require 'temporalio/client'
require_relative 'activities'
require_relative 'saga_workflow'

# Create a Temporal client
client = Temporalio::Client.connect('localhost:7233', 'default')

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
