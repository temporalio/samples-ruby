# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module Patching
  class MyWorkflow4Complete < Temporalio::Workflow::Definition
    workflow_name :MyWorkflow
    workflow_query_attr_reader :result

    def execute
      @result = Temporalio::Workflow.execute_activity(
        MyActivities::PostPatch,
        start_to_close_timeout: 5 * 60
      )
    end
  end
end
