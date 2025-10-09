# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'compose_greeting_activity'

module Polling
  module Frequent
    class GreetingWorkflow < Temporalio::Workflow::Definition
      def execute(name)
        Temporalio::Workflow.execute_activity(
          ComposeGreetingActivity,
          { greeting: 'Hello', name: name },
          start_to_close_timeout: 60,
          heartbeat_timeout: 2
        )
      end
    end
  end
end
