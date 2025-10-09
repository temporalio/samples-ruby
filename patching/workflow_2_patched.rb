# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module Patching
  class MyWorkflow2Patched < Temporalio::Workflow::Definition
    workflow_name 'MyWorkflow'
    workflow_query_attr_reader :result

    def execute
      # Decide which activity to use based on workflow's patch status
      @result = if Temporalio::Workflow.patched :my_patch
                  Temporalio::Workflow.execute_activity(
                    MyActivities::PostPatch,
                    start_to_close_timeout: 5 * 60
                  )
                else
                  Temporalio::Workflow.execute_activity(
                    MyActivities::PrePatch,
                    start_to_close_timeout: 5 * 60
                  )
                end
    end
  end
end
