# frozen_string_literal: true

require 'test'
require 'worker_versioning/app'
require 'worker_versioning/workerv1'
require 'worker_versioning/workerv1_1'
require 'worker_versioning/workerv2'
require 'temporalio/testing'

module WorkerVersioning
  class WorkerVersioningTest < Test
    def test_worker_versioning_sample_can_run
      skip_if_not_x86!

      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        worker_v1_task = Thread.new { WorkerVersioning::WorkerV1.run_async(env.client) }
        worker_v1_1_task = Thread.new { WorkerVersioning::WorkerV1Dot1.run_async(env.client) }
        worker_v2_task = Thread.new { WorkerVersioning::WorkerV2.run_async(env.client) }

        begin
          main(env.client)
          assert(true, 'Worker versioning demo completed successfully')
        ensure
          [worker_v1_task, worker_v1_1_task, worker_v2_task].each(&:kill)
        end
      end
    end
  end
end
