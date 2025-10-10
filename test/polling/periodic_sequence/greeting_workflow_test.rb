# frozen_string_literal: true

require 'test'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'
require 'polling/periodic_sequence/greeting_workflow'
require 'polling/periodic_sequence/compose_greeting_activity'
require 'polling/periodic_sequence/test_service'

module Polling
  module PeriodicSequence
    class GreetingWorkflowTest < Test
      def test_workflow_completes_after_polling
        task_queue = "tq-#{SecureRandom.uuid}"

        Temporalio::Testing::WorkflowEnvironment.start_time_skipping do |env|
          worker = Temporalio::Worker.new(
            client: env.client,
            task_queue: task_queue,
            activities: [Polling::PeriodicSequence::ComposeGreetingActivity],
            workflows: [Polling::PeriodicSequence::GreetingWorkflow, Polling::PeriodicSequence::ChildWorkflow]
          )

          handle = env.client.start_workflow(
            Polling::PeriodicSequence::GreetingWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: task_queue
          )

          worker.run do
            env.sleep(5)
            # Wait for the workflow to complete and assert its result
            result = handle.result
            assert_equal 'Hello, Temporal!', result
          end

          child_started_event = handle.fetch_history_events.filter_map do |e|
            e.child_workflow_execution_started_event_attributes&.workflow_type&.name
          end.first
          assert_equal 'ChildWorkflow', child_started_event
        end
      end
    end
  end
end
