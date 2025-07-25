# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'compose_greeting_activity'

module Polling
  module Infrequent
    class GreetingWorkflow < Temporalio::Workflow::Definition
      def execute(name)
        Temporalio::Workflow.execute_activity(
          ComposeGreetingActivity,
          { greeting: 'Hello', name: name },
          retry_policy: Temporalio::RetryPolicy.new(
            initial_interval: 1, # seconds
            backoff_coefficient: 1.0
          ),
          start_to_close_timeout: 2
        )
      end
    end
  end
end
