# frozen_string_literal: true

require 'test'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'
require 'polling/infrequent/greeting_workflow'
require 'polling/infrequent/compose_greeting_activity'
require 'polling/infrequent/test_service'

module Polling
  module Infrequent
    class GreetingWorkflowTest < Test
      def test_workflow_completes_after_polling
        skip_if_not_x86!
        task_queue = "tq-#{SecureRandom.uuid}"

        Temporalio::Testing::WorkflowEnvironment.start_time_skipping do |env|
          worker = Temporalio::Worker.new(
            client: env.client,
            task_queue: task_queue,
            activities: [Polling::Infrequent::ComposeGreetingActivity],
            workflows: [Polling::Infrequent::GreetingWorkflow]
          )

          handle = env.client.start_workflow(
            Polling::Infrequent::GreetingWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: task_queue
          )

          worker.run do
            # Advance time forward to allow for the 4 retries (4 * 60s) plus a buffer
            env.sleep(241)

            # Wait for the workflow to complete and assert its result
            result = handle.result
            assert_equal('Hello, Temporal!', result)
          end
        end
      end
    end
  end
end
