require 'temporalio/workflow'
require_relative './compose_greeting_activity'
require_relative './test_service'

module InfrequentPolling
  class GreetingWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      Temporalio::Workflow.execute_activity(
        ComposeGreetingActivity,
        TestService::ComposeGreetingInput.new('Hello', name),
        retry_policy: Temporal::RetryPolicy.new(
          initial_interval: 10, # seconds
          backoff_coefficient: 1.0,
        ),
        start_to_close_timeout: 5 * 60
      )
    end
  end
end