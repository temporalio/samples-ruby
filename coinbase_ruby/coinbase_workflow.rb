require 'temporal-ruby'
require_relative 'coinbase_activity'

module CoinbaseRuby
  class CoinbaseWorkflow < Temporal::Workflow
    def execute(name)
      [
        # Execute activity on Coinbase SDK worker
        CoinbaseActivity.execute!(name),
        # Execute activity on Temporal SDK worker
        workflow.execute_activity!(:TemporalActivity, name, options: { task_queue: 'coinbase-ruby-sample-temporal' })
      ]
    end
  end
end
