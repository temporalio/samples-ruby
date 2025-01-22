# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module ActivitySimple
  class MyWorkflow < Temporalio::Workflow::Definition
    def execute
      # Run an activity that needs some state like a database connection
      result1 = Temporalio::Workflow.execute_activity(
        MyActivities::SelectFromDatabase,
        'some-db-table',
        start_to_close_timeout: 5 * 60 # 5 minutes
      )
      Temporalio::Workflow.logger.info("Activity result 1: #{result1}")

      # Run a stateless activity (note no difference on the caller side)
      result2 = Temporalio::Workflow.execute_activity(
        MyActivities::AppendSuffix,
        result1,
        start_to_close_timeout: 5 * 60
      )
      Temporalio::Workflow.logger.info("Activity result 2: #{result2}")

      # We'll go ahead and return this result
      result2
    end
  end
end
