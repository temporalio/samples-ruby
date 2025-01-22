# frozen_string_literal: true

require 'test'
require 'message_passing_simple/call_greeting_service'
require 'message_passing_simple/greeting_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module MessagePassingSimple
  class GreetingWorkflowTest < Test
    def with_worker_running
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [CallGreetingService],
          workflows: [GreetingWorkflow]
        )
        worker.run { yield env.client, worker }
      end
    end

    def test_queries
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)
        assert_equal %w[chinese english], handle.query(GreetingWorkflow.languages, { include_unsupported: false })
        assert_equal CallGreetingService.greetings.keys.map(&:to_s).sort,
                     handle.query(GreetingWorkflow.languages, { include_unsupported: true })
      end
    end

    def test_set_language
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)
        prev_language = handle.execute_update(GreetingWorkflow.set_language, :chinese)
        assert_equal 'english', prev_language
        assert_equal 'chinese', handle.query(GreetingWorkflow.language)
      end
    end

    def test_set_language_invalid
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)
        assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
          handle.execute_update(GreetingWorkflow.set_language, :arabic)
        end
      end
    end

    def test_apply_language_with_lookup
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow, id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
        prev_language = handle.execute_update(GreetingWorkflow.apply_language_with_lookup, :arabic)
        assert_equal 'english', prev_language
        assert_equal 'arabic', handle.query(GreetingWorkflow.language)
      end
    end
  end
end
