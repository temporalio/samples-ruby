# frozen_string_literal: true

require 'test'
require 'client_mtls/greeting_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module ClientMtls
  class GreetingWorkflowTest < Test
    def test_workflow
      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [Activities::ComposeGreeting],
          workflows: [GreetingWorkflow]
        )
        worker.run do
          # Run workflow
          assert_equal(
            'Hello, World!',
            env.client.execute_workflow(GreetingWorkflow, 'World', id: "wf-#{SecureRandom.uuid}",
                                                                   task_queue: worker.task_queue)
          )
        end
      end
    end
  end
end
