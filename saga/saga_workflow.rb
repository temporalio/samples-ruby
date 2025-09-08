# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'activities'

module Saga
  class SagaWorkflow < Temporalio::Workflow::Definition
    def execute(details)
      # Collect compensation activities (aka activities to perform undo) in an array
      compensations = []

      # Perform some actions. Notice how we add compensations _before_ executing the associated activities. This is a
      # user choice, but usually it is best before because the activity may have run but the end of it failed or timed
      # out. The compensation should be smart enough to check what is about to undo before it does it.

      # Withdraw money
      compensations << Activities::WithdrawCompensation
      Temporalio::Workflow.execute_activity(Activities::Withdraw, details, start_to_close_timeout: 30)

      # Deposit money
      compensations << Activities::DepositCompensation
      Temporalio::Workflow.execute_activity(Activities::Deposit, details, start_to_close_timeout: 30)

      # Simulate a failure. This simulates a failure after withdraw and deposit, but this could just as easily be a
      # failure with either of those.
      Temporalio::Workflow.execute_activity(Activities::SomethingThatFails, details, start_to_close_timeout: 30)

      # Never reached
      nil
    rescue StandardError
      # Perform the compensations in reverse. It is user choice on whether a compensation failure should be allowed to
      # raise thereby swallowing the existing one, or if it should be swallowed. This sample raises the compensation
      # error because either error fails the workflow anyways and both errors are going to be visible in history.
      compensations.reverse_each do |compensating_activity|
        Temporalio::Workflow.execute_activity(compensating_activity, details, start_to_close_timeout: 30)
      end

      # Re-raise
      raise
    end
  end
end
