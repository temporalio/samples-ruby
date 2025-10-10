# frozen_string_literal: true

require 'test'
require 'eager_workflow_start/eager_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module EagerWorkflowStart
  class EagerWorkflowTest < Test
    def test_workflow
      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [GreetingActivity],
          workflows: [EagerWorkflow]
        )
        worker.run do
          # Run workflow with eager start
          result = env.client.execute_workflow(
            EagerWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue,
            request_eager_start: true
          )
          assert_equal('Hello, Temporal!', result)
        end
      end
    end
  end
end
