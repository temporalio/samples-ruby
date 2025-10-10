# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'compose_greeting_activity'
require_relative 'test_service'

module Polling
  module PeriodicSequence
    class ChildWorkflow < Temporalio::Workflow::Definition
      def execute(name)
        4.times do
          begin
            return Temporalio::Workflow.execute_activity(
              ComposeGreetingActivity,
              { greeting: 'Hello', name: name },
              retry_policy: Temporalio::RetryPolicy.new(
                max_attempts: 1
              ),
              start_to_close_timeout: 4
            )
          rescue Temporalio::Error::ActivityError
            Temporalio::Workflow.logger.info('Activity failed')
          end
          Temporalio::Workflow.sleep(1)
        end
        raise Temporalio::Workflow::ContinueAsNewError, name
      end
    end
  end
end
