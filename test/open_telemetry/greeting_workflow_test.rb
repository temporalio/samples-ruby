# frozen_string_literal: true

require 'test'
require 'open_telemetry/compose_greeting_activity'
require 'open_telemetry/greeting_workflow'
require 'opentelemetry/sdk'
require 'securerandom'
require 'temporalio/client'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/testing'
require 'temporalio/worker'

module OpenTelemetry
  class GreetingWorkflowTest < Test
    def test_workflow
      # Setup in memory buffer for telemetry events
      metrics_buffer = Temporalio::Runtime::MetricBuffer.new(1024)
      runtime = Temporalio::Runtime.new(
        telemetry: Temporalio::Runtime::TelemetryOptions.new(
          metrics: Temporalio::Runtime::MetricsOptions.new(
            buffer: metrics_buffer
          )
        )
      )
      tracer = OpenTelemetry.tracer_provider.tracer('opentelemetry_sample_test', '1.0.0')
      Temporalio::Testing::WorkflowEnvironment.start_local(
        runtime:,
        interceptors: [Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(tracer)]
      ) do |env|
        # Run workflow in a worker
        env.client
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [ComposeGreetingActivity.new(tracer)],
          workflows: [GreetingWorkflow]
        )
        result = worker.run do
          handle = env.client.start_workflow(
            GreetingWorkflow, 'Temporal',
            id: "wf-#{SecureRandom.uuid}",
            task_queue: worker.task_queue
          )
          handle.result
        end
        assert_equal 'Hello, Temporal!', result
        assert !metrics_buffer.retrieve_updates.empty?
      end
    end
  end
end
