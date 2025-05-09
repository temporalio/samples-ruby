# frozen_string_literal: true

require 'test'
require 'activity_simple/my_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module ActivitySimple
  class MyWorkflowTest < Test
    # Demonstrates mocking out activities
    class MockSelectFromDatabase < Temporalio::Activity::Definition
      activity_name :SelectFromDatabase

      def execute(table)
        "mocked value from #{table}"
      end
    end

    def test_workflow
      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [MockSelectFromDatabase, MyActivities::AppendSuffix],
          workflows: [MyWorkflow]
        )
        worker.run do
          # Run workflow
          assert_equal(
            'mocked value from some-db-table <appended-value>',
            env.client.execute_workflow(MyWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
          )
        end
      end
    end
  end
end
