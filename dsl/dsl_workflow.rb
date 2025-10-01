# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'models'

module Dsl
  class DslWorkflow < Temporalio::Workflow::Definition
    def execute(input)
      # Run and return the final variable set
      Temporalio::Workflow.logger.info('Running DSL workflow')
      @variables = input.variables
      execute_statement(input.root)
      Temporalio::Workflow.logger.info('DSL workflow completed')
      @variables
    end

    def execute_statement(stmt)
      case stmt
      when Models::Statement::Activity
        # Invoke activity loading arguments from variables and optionally storing result as a variable
        result = Temporalio::Workflow.execute_activity(
          stmt.name,
          *stmt.arguments.map { |a| @variables[a] },
          start_to_close_timeout: 60
        )
        @variables[stmt.result] = result if stmt.result
      when Models::Statement::Sequence
        # Execute each statement in order
        stmt.elements.each { |s| execute_statement(s) }
      when Models::Statement::Parallel
        # Execute all in parallel. Note, this will raise an exception when the first activity fails and will not cancel
        # the others. We could provide a linked Cancellation to each and cancel it on error if we wanted.
        Temporalio::Workflow::Future.all_of(
          *stmt.branches.map { |s| Temporalio::Workflow::Future.new { execute_statement(s) } }
        ).wait
      end
    end
  end
end
