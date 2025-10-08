# frozen_string_literal: true

require 'test'
require 'updatable_timer/updatable_timer_workflow'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'

module UpdatableTimer
  class UpdatableTimerWorkflowTest < Test
    def test_workflow
      Temporalio::Testing::WorkflowEnvironment.start_time_skipping do |env|
        # Run workflow in a worker
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          workflows: [UpdatableTimerWorkflow]
        )
        worker.run do
          day_from_now = (Time.now(in: 'utc') + (24 * 60 * 60)).to_r
          hour_from_now = (Time.now(in: 'utc') + (60 * 60)).to_r
          handle = env.client.start_workflow(
            UpdatableTimerWorkflow, day_from_now,
            id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue
          )
          assert_equal day_from_now, Rational(handle.query(UpdatableTimerWorkflow.wake_up_time))
          handle.signal(UpdatableTimerWorkflow.update_wake_up_time, hour_from_now)
          assert_equal hour_from_now, Rational(handle.query(UpdatableTimerWorkflow.wake_up_time))

          handle.result
        end
      end
    end
  end
end
