# frozen_string_literal: true

require 'securerandom'
require 'test'
require 'temporalio/testing'
require 'temporalio/worker'
ENV['COINBASE_TEMPORAL_RUBY_DISABLE_PROTO_LOAD'] = '1'
require 'temporal-ruby'
require 'temporal/worker'

require 'coinbase_ruby/coinbase_workflow'
require 'coinbase_ruby/temporal_workflow'

module CoinbaseRuby
  class WorkflowTest < Test
    def test_both_sdks
      # Start a local env
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Create Coinbase config, client, and worker
        coinbase_config = Temporal::Configuration.new
        host, port = env.client.connection.options.target_host.split(':')
        coinbase_config.host = host
        coinbase_config.port = port.to_i
        coinbase_config.namespace = 'default'
        coinbase_config.task_queue = 'coinbase-ruby-sample-coinbase'
        coinbase_client = Temporal::Client.new(coinbase_config)
        coinbase_worker = Temporal::Worker.new(coinbase_config)
        coinbase_worker.register_activity(CoinbaseRuby::CoinbaseActivity)
        coinbase_worker.register_workflow(CoinbaseRuby::CoinbaseWorkflow)

        # Run all inside Temporal worker
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: 'coinbase-ruby-sample-temporal',
          activities: [CoinbaseRuby::TemporalActivity],
          workflows: [CoinbaseRuby::TemporalWorkflow]
        )
        worker.run do
          # Run Coinbase worker in background, stop it when done
          Thread.new { coinbase_worker.start }

          # Run both workflows from Temporal client
          assert_equal ['Hello from Coinbase Ruby SDK, user-a!', 'Hello from Temporal Ruby SDK, user-a!'],
                       env.client.execute_workflow(
                         CoinbaseRuby::CoinbaseWorkflow.name, 'user-a',
                         id: "wf-#{SecureRandom.uuid}", task_queue: 'coinbase-ruby-sample-coinbase'
                       )
          assert_equal ['Hello from Coinbase Ruby SDK, user-b!', 'Hello from Temporal Ruby SDK, user-b!'],
                       env.client.execute_workflow(
                         CoinbaseRuby::TemporalWorkflow, 'user-b',
                         id: "wf-#{SecureRandom.uuid}", task_queue: 'coinbase-ruby-sample-temporal'
                       )

          # Run both workflows from Coinbase client
          workflow_id = "wf-#{SecureRandom.uuid}"
          run_id = coinbase_client.start_workflow(
            CoinbaseRuby::CoinbaseWorkflow, 'user-c',
            options: { workflow_id:, task_queue: 'coinbase-ruby-sample-coinbase' }
          )
          assert_equal ['Hello from Coinbase Ruby SDK, user-c!', 'Hello from Temporal Ruby SDK, user-c!'],
                       coinbase_client.await_workflow_result(CoinbaseRuby::CoinbaseWorkflow, workflow_id:, run_id:)
          workflow_id = "wf-#{SecureRandom.uuid}"
          run_id = coinbase_client.start_workflow(
            :TemporalWorkflow, 'user-d',
            options: { workflow_id:, task_queue: 'coinbase-ruby-sample-temporal' }
          )
          assert_equal ['Hello from Coinbase Ruby SDK, user-d!', 'Hello from Temporal Ruby SDK, user-d!'],
                       coinbase_client.await_workflow_result(:TemporalWorkflow, workflow_id:, run_id:)
        ensure
          coinbase_worker.stop
        end
      end
    end
  end
end
