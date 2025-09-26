# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module AsyncActivity
  class MyWorkflow < Temporalio::Workflow::Definition
    def execute
      # Run an activity that needs some state like a database connection
      result1 = Temporalio::Workflow.execute_activity(
        MyActivities::SelectFromDatabase,
        'some-db-table',
        start_to_close_timeout: 5 * 60 # 5 minutes
      )
      Temporalio::Workflow.logger.info("Activity result 1: #{result1}")

      # Run a stateless activity (note no difference on the caller side)
      futures = []
      results = []
      values = (1..10).to_a

      values.each do |val|
        Temporalio::Workflow.logger.info("Starting: #{val}")

        future = Temporalio::Workflow::Future.new do
          begin
            Temporalio::Workflow.logger.info("Calling Async Operation: #{val}")

            Temporalio::Workflow.execute_activity(
              MyActivities::ExecuteAsyncOperation,
              [val],
              # start_to_close_timeout: 60,
              schedule_to_close_timeout: 86400 * 365
            )
            Temporalio::Workflow.logger.info("Called Async Operation: #{val}")

          rescue e
            Temporalio::Workflow.logger.info("ERROR!: #{e}")
          end

        end
        Temporalio::Workflow.logger.info("Adding Async Operation Future: #{val}")

        futures << future
      end
      completed_futures = []
      # Temporalio::Workflow.logger.info("Activity result 2: #{result2}")
      Temporalio::Workflow.logger.info("Waiting: #{results}")
      loop do
        Temporalio::Workflow::Future.any_of(*futures).wait
        completed_futures << futures.select { |future| future.done? }
        Temporalio::Workflow.logger.info("Completed futures count: #{completed_futures.size}")
        futures.reject! { |future| completed_futures.include?(future) }
        Temporalio::Workflow.logger.info("Pending futures count: #{futures.size}")
        if futures.empty?
          break
        end
      end
      Temporalio::Workflow.logger.info("Completed futures!!!")

      # We'll go ahead and return this result
      results
    end
  end
end
