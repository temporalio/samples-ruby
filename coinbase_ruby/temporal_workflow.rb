# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'coinbase_activity'
require_relative 'temporal_activity'

module CoinbaseRuby
  class TemporalWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      [
        # Execute activity on Coinbase SDK worker
        Temporalio::Workflow.execute_activity(CoinbaseActivity.name, name,
                                              start_to_close_timeout: 10, task_queue: 'coinbase-ruby-sample-coinbase'),
        # Execute activity on Temporal SDK worker
        Temporalio::Workflow.execute_activity(TemporalActivity, name, start_to_close_timeout: 10)
      ]
    end
  end
end
