# frozen_string_literal: true

require 'minitest/autorun'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'
require_relative '../../dsl/dsl_workflow'
require_relative '../../dsl/dsl_models'
require_relative '../../dsl/activities'

module Dsl
  class DslWorkflowTest < Minitest::Test
    def test_workflow1
      yaml_content = File.read(File.join(File.dirname(__FILE__), '../../dsl/workflow1.yaml'))

      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "dsl-test-queue-#{SecureRandom.uuid}",
          activities: [
            Activities::Activity1,
            Activities::Activity2,
            Activities::Activity3,
            Activities::Activity4,
            Activities::Activity5
          ],
          workflows: [DslWorkflow]
        )
        worker.run do
          # Run workflow with the first YAML file
          workflow_id = "dsl-workflow1-test-#{SecureRandom.uuid}"
          result = env.client.execute_workflow(
            DslWorkflow,
            yaml_content,
            id: workflow_id,
            task_queue: worker.task_queue
          )

          # Simply check that the workflow completes - no need to verify results
          assert result.is_a?(Hash), "Expected result to be a Hash, got #{result.class}"
        end
      end
    end

    def test_workflow2
      yaml_content = File.read(File.join(File.dirname(__FILE__), '../../dsl/workflow2.yaml'))

      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "dsl-test-queue-#{SecureRandom.uuid}",
          activities: [
            Activities::Activity1,
            Activities::Activity2,
            Activities::Activity3,
            Activities::Activity4,
            Activities::Activity5
          ],
          workflows: [DslWorkflow]
        )
        worker.run do
          # Run workflow with the second YAML file
          workflow_id = "dsl-workflow2-test-#{SecureRandom.uuid}"
          result = env.client.execute_workflow(
            DslWorkflow,
            yaml_content,
            id: workflow_id,
            task_queue: worker.task_queue
          )

          # Simply check that the workflow completes - no need to verify results
          assert result.is_a?(Hash), "Expected result to be a Hash, got #{result.class}"
        end
      end
    end
  end
end
