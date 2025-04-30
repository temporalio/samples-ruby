# frozen_string_literal: true

require 'test'
require 'worker_specific_task_queues/file_processing_workflow'
require 'worker_specific_task_queues/normal_activities'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module WorkerSpecificTaskQueues
  module WorkerSpecificActivities
    class DownloadFileActivity < Temporalio::Activity::Definition
      def execute(url)
        url
      end
    end

    class WorkOnFileActivity < Temporalio::Activity::Definition
      @failed = false

      class << self
        attr_accessor :failed
      end

      def execute(_file_path)
        # This should fail the first time it's called
        unless self.class.failed
          self.class.failed = true
          raise 'Fake failure'
        end

        nil
      end
    end

    class CleanupFileActivity < Temporalio::Activity::Definition
      def execute(_file_path)
        nil
      end
    end
  end

  class FileProcessingWorkflowTest < Test
    def test_workflow
      # Run test server until completion of the block
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        unique_task_queue = "tq-#{SecureRandom.uuid}"
        unique_worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: unique_task_queue,
          activities: [WorkerSpecificActivities::DownloadFileActivity, WorkerSpecificActivities::WorkOnFileActivity,
                       WorkerSpecificActivities::CleanupFileActivity]
        )

        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [WorkerSpecificTaskQueues::NormalActivities::GetUniqueTaskQueueActivity.new(unique_task_queue)],
          workflows: [WorkerSpecificTaskQueues::FileProcessingWorkflow]
        )
        unique_worker.run do
          worker.run do
            # Run workflow
            env.client.execute_workflow(WorkerSpecificTaskQueues::FileProcessingWorkflow, 2,
                                        id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue)
          end
        end
      end
    end
  end
end
