# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'say_hello_activity'

module ContextPropagation
  class SayHelloWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      Temporalio::Workflow.logger.info("Workflow called by user: #{Thread.current[:my_user]}")

      # Wait for signal then run activity
      Temporalio::Workflow.wait_condition { @complete }
      Temporalio::Workflow.execute_activity(SayHelloActivity, name, start_to_close_timeout: 5 * 60)
    end

    workflow_signal
    def signal_complete
      Temporalio::Workflow.logger.info("Signal called by user: #{Thread.current[:my_user]}")
      @complete = true
    end

    workflow_query
    def complete?
      Temporalio::Workflow.logger.info("Query called by user: #{Thread.current[:my_user]}")
      @complete
    end
  end
end
