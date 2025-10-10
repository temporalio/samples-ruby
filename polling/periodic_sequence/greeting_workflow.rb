# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'child_workflow'

module Polling
  module PeriodicSequence
    class GreetingWorkflow < Temporalio::Workflow::Definition
      def execute(name)
        Temporalio::Workflow.execute_child_workflow(ChildWorkflow, name)
      end
    end
  end
end
