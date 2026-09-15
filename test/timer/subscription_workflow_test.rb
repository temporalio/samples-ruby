# frozen_string_literal: true

require 'test'
require 'timer/subscription_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module Timer
  class SubscriptionWorkflowTest < Test
    def test_workflow_charges_and_cancels
      Temporalio::Testing::WorkflowEnvironment.start_time_skipping do |env|
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [MyActivities::Charge],
          workflows: [SubscriptionWorkflow]
        )
        worker.run do
          handle = env.client.start_workflow(
            SubscriptionWorkflow,
            'test-user',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue
          )

          # Wait a bit for the workflow to start and the timer to be set
          env.sleep(31 * 24 * 60 * 60) # 31 days — past the first charge

          # Cancel the workflow
          handle.cancel

          # Workflow should complete as cancelled
          err = assert_raises(Temporalio::Error::WorkflowFailedError) { handle.result }
          assert_kind_of Temporalio::Error::CanceledError, err.cause
        end
      end
    end
  end
end
