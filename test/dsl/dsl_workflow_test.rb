# frozen_string_literal: true

require 'test'
require 'dsl/activities'
require 'dsl/models'
require 'dsl/dsl_workflow'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'

module Dsl
  class DslWorkflowTest < Test
    def test_workflow
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Load the YAML from workflow2.yaml
        yaml_str = File.read(File.join(File.dirname(__FILE__), '../../dsl/workflow2.yaml'))
        # Run workflow in a worker
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [Activities::Activity1, Activities::Activity2, Activities::Activity3,
                       Activities::Activity4, Activities::Activity5],
          workflows: [DslWorkflow]
        )
        handle, result = worker.run do
          handle = env.client.start_workflow(
            DslWorkflow, Models::Input.from_yaml(yaml_str),
            id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue
          )
          [handle, handle.result]
        end
        # Confirm expected variable results
        assert_equal(
          {
            'arg1' => 'value1',
            'arg2' => 'value2',
            'arg3' => 'value3',
            'result1' => '[result from activity1: value1]',
            'result2' => '[result from activity2: [result from activity1: value1]]',
            'result3' => '[result from activity3: value2 [result from activity2: [result from activity1: value1]]]',
            'result4' => '[result from activity4: [result from activity1: value1]]',
            'result5' => '[result from activity5: value3 [result from activity4: [result from activity1: value1]]]',
            'result6' => '[result from activity3: [result from activity3: value2 [result from activity2: ' \
                         '[result from activity1: value1]]] [result from activity5: ' \
                         'value3 [result from activity4: [result from activity1: value1]]]]'
          },
          result
        )
        # Collect all activity events and confirm they are in order expected
        activity_names = handle.fetch_history_events
                               .map { |e| e.activity_task_scheduled_event_attributes&.activity_type&.name }
                               .compact
        assert_equal 'activity1', activity_names[0]
        assert_equal %w[activity2 activity3 activity4 activity5], activity_names[1, 4].sort
        assert_equal 'activity3', activity_names[5]
      end
    end
  end
end
