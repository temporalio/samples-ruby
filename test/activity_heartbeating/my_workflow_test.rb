# frozen_string_literal: true

require 'test'
require 'activity_heartbeating/my_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module ActivityHeartbeating
  class MyWorkflowTest < Test
    def test_workflow
      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [MyActivities::FakeProgress],
          workflows: [MyWorkflow]
        )
        worker.run do
          # Start workflow
          wf = env.client.start_workflow(MyWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)

          # Cancel workflow
          wf.cancel

          # Check that it was cancelled
          assert_raises(Temporalio::Error::WorkflowFailedError, 'Workflow execution canceled') do
            wf.result
          end
        end
      end
    end
  end
end
