# frozen_string_literal: true

require 'test'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'
require 'polling/frequent/greeting_workflow'
require 'polling/frequent/compose_greeting_activity'
require 'polling/frequent/test_service'

module Polling
  module Frequent
    class GreetingWorkflowTest < Test
      def test_workflow_completes_after_polling
        task_queue = "tq-#{SecureRandom.uuid}"

        Temporalio::Testing::WorkflowEnvironment.start_local do |env|
          worker = Temporalio::Worker.new(
            client: env.client,
            task_queue: task_queue,
            activities: [Polling::Frequent::ComposeGreetingActivity],
            workflows: [Polling::Frequent::GreetingWorkflow]
          )

          handle = env.client.start_workflow(
            Polling::Frequent::GreetingWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: task_queue
          )

          worker.run do
            # Wait for the workflow to complete and assert its result
            result = handle.result
            assert_equal('Hello, Temporal!', result)
          end
        end
      end
    end
  end
end
