# frozen_string_literal: true

require 'test'
require 'securerandom'
require 'saga/activities'
require 'saga/saga_workflow'
require 'temporalio/testing'
require 'temporalio/worker'
require 'polling/infrequent/compose_greeting_activity'
require 'polling/test_service'

module Saga
  class SagaWorkflowTest < Test
    def test_workflow_runs_compensations
      # Run worker in test environment
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [Activities::Withdraw, Activities::WithdrawCompensation,
                       Activities::Deposit, Activities::DepositCompensation,
                       Activities::SomethingThatFails],
          workflows: [SagaWorkflow]
        )
        worker.run do
          # Start workflow
          handle = env.client.start_workflow(
            SagaWorkflow,
            Saga::Activities::TransferDetails.new(
              amount: 100,
              from_account: 'acc1000',
              to_account: 'acc2000',
              reference_id: '1324'
            ),
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue
          )

          # Confirm it failed as expected
          err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
          assert_instance_of(Temporalio::Error::ActivityError, err.cause)
          assert_instance_of(Temporalio::Error::ApplicationError, err.cause.cause)
          assert_equal('Simulated failure', err.cause.cause.message)

          # Confirm last two events are the compensations
          activity_events = handle.fetch_history_events.map(&:activity_task_scheduled_event_attributes).compact
          assert_equal('DepositCompensation', activity_events[-2].activity_type.name)
          assert_equal('WithdrawCompensation', activity_events[-1].activity_type.name)
        end
      end
    end
  end
end
