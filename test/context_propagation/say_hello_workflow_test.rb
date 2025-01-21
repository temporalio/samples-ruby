# frozen_string_literal: true

require 'test'
require 'context_propagation/interceptor'
require 'context_propagation/say_hello_activity'
require 'context_propagation/say_hello_workflow'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/testing'
require 'temporalio/worker'

module ContextPropagation
  class SayHelloWorkflowTest < Test
    def test_workflow
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Add the interceptor to the client
        client = Temporalio::Client.new(**env.client.options.with(
          interceptors: [Interceptor.new(:my_user)]
        ).to_h)

        worker = Temporalio::Worker.new(
          client:,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [SayHelloActivity],
          workflows: [SayHelloWorkflow]
        )
        worker.run do
          # Start workflow with thread local, send signal, confirm result
          Thread.current[:my_user] = 'some-user'
          handle = client.start_workflow(
            SayHelloWorkflow,
            'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue
          )
          handle.signal(SayHelloWorkflow.signal_complete)
          assert_equal('Hello, Temporal! (called by user some-user)', handle.result)
        end
      end
    end
  end
end
