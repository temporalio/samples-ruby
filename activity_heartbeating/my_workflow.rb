# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module ActivityHeartbeating
  class MyWorkflow < Temporalio::Workflow::Definition
    def execute
      # Execute the activity with a 5-minute timeout and 3-second heartbeat timeout
      Temporalio::Workflow.execute_activity(
        MyActivities::FakeProgress,
        1000, # 1 second sleep interval
        start_to_close_timeout: 5 * 60,
        heartbeat_timeout: 3,
        # Wait for activity cancellation completion
        cancellation_type: Temporalio::Workflow::ActivityCancellationType::WAIT_CANCELLATION_COMPLETED
      )
    rescue Temporalio::Error::CanceledError
      # This catches the cancel just for demonstration, you usually don't want to catch it
      Temporalio::Workflow.logger.info('Workflow cancelled along with its activity')
      raise # Re-raise to properly cancel the workflow
    end
  end
end
