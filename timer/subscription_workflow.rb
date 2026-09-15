# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'my_activities'

module Timer
  class SubscriptionWorkflow < Temporalio::Workflow::Definition
    def execute(user_id)
      loop do
        Temporalio::Workflow.sleep(30 * 24 * 60 * 60) # 30 days

        result = Temporalio::Workflow.execute_activity(
          MyActivities::Charge,
          user_id,
          start_to_close_timeout: 5 * 60
        )
        Temporalio::Workflow.logger.info("Activity result: #{result}")
      end
    rescue Temporalio::Error::CanceledError
      Temporalio::Workflow.logger.info('Workflow cancelled, cleaning up...')
      raise
    end
  end
end
