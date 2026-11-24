# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'greeting_activity'

module AwsLambda
  class GreetingWorkflow < Temporalio::Workflow::Definition
    workflow_name 'LambdaGreetingWorkflow'

    def execute(name)
      Temporalio::Workflow.execute_activity(GreetingActivity, name, start_to_close_timeout: 10)
    end
  end
end
