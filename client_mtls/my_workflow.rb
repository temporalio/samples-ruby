# frozen_string_literal: true

require_relative 'my_activities'
require 'temporalio/workflow'

module ClientMtls
  class GreetingWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      # Execute activity and return result
      Temporalio::Workflow.execute_activity(
        Activities::ComposeGreeting,
        'Hello',
        name,
        start_to_close_timeout: 10
      )
    end
  end
end
