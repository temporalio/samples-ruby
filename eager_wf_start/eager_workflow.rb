# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'greeting_activity'

module EagerWfStart
  class EagerWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      Temporalio::Workflow.execute_local_activity(
        GreetingActivity,
        name,
        schedule_to_close_timeout: 5
      )
    end
  end
end
