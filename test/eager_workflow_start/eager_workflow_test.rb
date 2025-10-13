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
      Temporalio::Testing::WorkflowEnvironment.start_local(
        dev_server_download_version: 'latest'
      ) do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [GreetingActivity],
          workflows: [EagerWorkflow]
        )
        worker.run do
          # Start workflow with eager start
          handle = env.client.start_workflow(
            EagerWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue,
            request_eager_start: true
          )
          assert_equal('Hello, Temporal!', handle.result)

          # Verify workflow was eagerly executed
          started_event = handle.fetch_history_events.find(&:workflow_execution_started_event_attributes)
          assert(started_event.workflow_execution_started_event_attributes.eager_execution_accepted)
        end
      end
    end
  end
end
