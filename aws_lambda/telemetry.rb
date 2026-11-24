# frozen_string_literal: true

require 'opentelemetry/exporter/otlp'
require 'opentelemetry/sdk'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/runtime'
require 'temporalio/simple_plugin'

module AwsLambda
  # Application-owned resources configured once and reused across warm invocations.
  module Telemetry
    def self.configure(options)
      OpenTelemetry::SDK.configure do |config|
        config.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'ruby-lambda-worker')
        config.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            OpenTelemetry::Exporter::OTLP::Exporter.new(
              endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'http://127.0.0.1:4318/v1/traces')
            )
          )
        )
      end
      provider = OpenTelemetry.tracer_provider
      tracing = Temporalio::SimplePlugin.new(
        name: 'application-tracing',
        client_interceptors: [
          Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(provider.tracer('temporal-ruby'))
        ]
      )
      runtime = Temporalio::Runtime.new(
        telemetry: Temporalio::Runtime::TelemetryOptions.new(
          metrics: Temporalio::Runtime::MetricsOptions.new(
            opentelemetry: Temporalio::Runtime::OpenTelemetryMetricsOptions.new(
              url: ENV.fetch('TEMPORAL_METRICS_ENDPOINT', 'http://127.0.0.1:4317'),
              metric_periodicity: 1,
              durations_as_seconds: true
            ),
            global_tags: { 'service.name' => ENV.fetch('OTEL_SERVICE_NAME', 'ruby-lambda-worker') }
          )
        )
      )
      options.with(
        client_options: options.client_options.merge(runtime:),
        plugins: options.plugins + [tracing],
        shutdown_hooks: options.shutdown_hooks + [
          ->(remaining) { provider.force_flush(timeout: remaining) if remaining.positive? }
        ]
      )
    end
  end
end
