# frozen_string_literal: true

require 'temporalio/activity'

module WorkerSpecificTaskQueues
  module Activities
    class GetUniqueTaskQueueActivity < Temporalio::Activity::Definition
      def initialize(unique_task_queue)
        @unique_task_queue = unique_task_queue
      end

      def execute(*)
        # Return the known worker-specific task queue
        # that was provided during initialization
        @unique_task_queue
      end
    end
  end
end
