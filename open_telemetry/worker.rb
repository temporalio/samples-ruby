# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'temporalio/client'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/runtime'
require 'temporalio/worker'
require_relative 'compose_greeting_activity'
require_relative 'greeting_workflow'
require_relative 'util'

# Configure metrics and tracing
OpenTelemetry::Util.configure_metrics_and_tracing

# Demonstrate that we can create a custom metric right on the runtime, though most users won't need this
Temporalio::Runtime.default.metric_meter.create_metric(:gauge, 'my-worker-gauge', value_type: :float)
                   .with_additional_attributes({ 'my-group-attr' => 'simple-workers' })
                   .record(1.23)

# Create a client with the tracing interceptor set using the tracer
tracer = OpenTelemetry.tracer_provider.tracer('opentelemetry_sample', '1.0.0')
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  interceptors: [Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(tracer)]
)

# Run worker
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'opentelemetry-sample',
  activities: [OpenTelemetry::ComposeGreetingActivity.new(tracer)],
  workflows: [OpenTelemetry::GreetingWorkflow]
)
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
