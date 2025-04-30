# frozen_string_literal: true

require_relative 'normal_activities'
require_relative 'worker_specific_activities'
require 'temporalio/workflow'

module WorkerSpecificTaskQueues
  class FileProcessingWorkflow < Temporalio::Workflow::Definition
    def execute(max_attempts)
      attempt = 0

      loop do
        attempt += 1
        begin
          process_file
          return
        rescue StandardError => e
          # If it's at max attempts, re-raise to fail the workflow
          if attempt >= max_attempts
            Temporalio::Workflow.logger.error(
              "File processing failed and reached #{attempt} attempts, failing workflow: #{e.message}"
            )
            raise
          end
          # Otherwise, just warn and continue
          Temporalio::Workflow.logger.warn(
            "File processing failed on attempt #{attempt}, trying again: #{e.message}"
          )
        end
      end
    end

    private

    def process_file
      # Get a unique task queue from any worker
      unique_worker_task_queue = Temporalio::Workflow.execute_activity(
        Activities::GetUniqueTaskQueueActivity,
        nil,
        start_to_close_timeout: 60
      )

      # Download the file on the specific worker
      download_path = Temporalio::Workflow.execute_activity(
        Activities::DownloadFileActivity,
        'https://temporal.io',
        task_queue: unique_worker_task_queue,
        schedule_to_close_timeout: 300,
        heartbeat_timeout: 60
      )

      # Process the file on the same worker
      Temporalio::Workflow.execute_activity(
        Activities::WorkOnFileActivity,
        download_path,
        task_queue: unique_worker_task_queue,
        schedule_to_close_timeout: 300,
        heartbeat_timeout: 60
      )

      # Clean up the file on the same worker
      Temporalio::Workflow.execute_activity(
        Activities::CleanupFileActivity,
        download_path,
        task_queue: unique_worker_task_queue,
        schedule_to_close_timeout: 300,
        heartbeat_timeout: 60
      )
    end
  end
end
