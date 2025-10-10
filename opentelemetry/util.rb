require 'opentelemetry/exporter/otlp'
require 'opentelemetry/sdk'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/runtime'

module OpenTelemetrySample
  module Util
    def self.configure_metrics_and_tracing
      # Before doing anything, configure the default runtime with OpenTelemetry metrics. Unlike OpenTelemetry tracing in
      # Temporal, OpenTelemetry metrics does not use the Ruby OpenTelemetry library, but rather an internal one.
      Temporalio::Runtime.default = Temporalio::Runtime.new(
        telemetry: Temporalio::Runtime::TelemetryOptions.new(
          metrics: Temporalio::Runtime::MetricsOptions.new(
            opentelemetry: Temporalio::Runtime::OpenTelemetryMetricsOptions.new(
              url: 'http://127.0.0.1:4317',
              durations_as_seconds: true
            )
          )
        )
      )
      # Globally configure the Ruby OpenTelemetry library for tracing purposes. As of this writing, OpenTelemetry Ruby does
      # not support OTLP over gRPC, so we use the HTTP endpoint instead.
      OpenTelemetry::SDK.configure do |c|
        c.service_name = 'my-service'
        c.use_all
        # Can use a SimpleSpanProcessor instead of a BatchSpanProcessor, but batch is better for production and moves
        # the span exporting outside of the workflow instead of synchronously inside the workflow context.
        processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
          OpenTelemetry::Exporter::OTLP::Exporter.new(
            endpoint: 'http://localhost:4318/v1/traces'
          )
        )
        c.add_span_processor(processor)
        # We need to shutdown the batch span processor on process exit to flush spans
        at_exit { processor.shutdown }
      end
    end
  end
end
