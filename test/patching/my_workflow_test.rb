# frozen_string_literal: true

require 'test'
require 'patching/my_activities'
require 'patching/workflow_1_initial'
require 'patching/workflow_2_patched'
require 'patching/workflow_3_deprecated'
require 'patching/workflow_4_complete'

require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'

module Patching
  class PatchingWorkflowTest < Test
    def setup
      @task_queue = "tq-#{SecureRandom.uuid}"
    end

    def with_handle(env, workflow, id)
      Temporalio::Worker.new(
        client: env.client,
        activities: [MyActivities::PrePatch, MyActivities::PostPatch],
        task_queue: @task_queue,
        workflows: [workflow]
      ).run do
        handle = env.client.start_workflow(
          :MyWorkflow, id:, task_queue: @task_queue
        )
        yield handle
      end
    end

    def test_workflow
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        initial_handle = with_handle(env, MyWorkflow1Initial, 'initial-id') do |handle|
          handle.result
          assert_equal 'pre-patch', handle.query(:result)
          handle
        end

        patched_handle = with_handle(env, MyWorkflow2Patched, 'patched-id') do |handle|
          handle.result
          assert_equal 'pre-patch', initial_handle.query(:result)
          assert_equal 'post-patch', handle.query(:result)
          handle
        end

        deprecated_handle = with_handle(env, MyWorkflow3Deprecated, 'deprecated-id') do |handle|
          handle.result
          assert_raises(Temporalio::Error::WorkflowQueryFailedError) { initial_handle.query(:result) }
          assert_equal 'post-patch', patched_handle.query(:result)
          assert_equal 'post-patch', handle.query(:result)
          handle
        end

        with_handle(env, MyWorkflow4Complete, 'deprecated-id') do |complete_handle|
          complete_handle.result
          assert_raises(Temporalio::Error::WorkflowQueryFailedError) { initial_handle.query(:result) }
          assert_raises(Temporalio::Error::WorkflowQueryFailedError) { patched_handle.query(:result) }
          assert_equal 'post-patch', deprecated_handle.query(:result)
          assert_equal 'post-patch', complete_handle.query(:result)
        end
      end
    end
  end
end
