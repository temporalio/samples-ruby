# frozen_string_literal: true

require 'test'
require 'minitest/mock'
require 'aws_lambda/telemetry'

module AwsLambda
  class TelemetryTest < Test
    # The composition only needs these fields; the regular bundle does not yet
    # include the experimental LambdaWorker::Options class.
    Options = Data.define(:client_options, :plugins, :shutdown_hooks)

    def test_compose_tracing_and_budgeted_flush_without_owning_provider_shutdown
      budgets = []
      provider = Object.new
      provider.define_singleton_method(:tracer) { |_name| OpenTelemetry::Trace::Tracer.new }
      provider.define_singleton_method(:force_flush) { |timeout:| budgets << timeout }
      provider.define_singleton_method(:shutdown) { raise 'Must not shut down a reusable provider' }
      runtime = Object.new
      runtime_options = nil
      original_plugin = Object.new
      original_hook = ->(_remaining) {}
      original = Options.new(
        client_options: { namespace: 'example' }, plugins: [original_plugin], shutdown_hooks: [original_hook]
      )
      runtime_factory = lambda do |**kwargs|
        runtime_options = kwargs
        runtime
      end

      configured = OpenTelemetry::SDK.stub(:configure, -> {}) do
        OpenTelemetry.stub(:tracer_provider, provider) do
          Temporalio::Runtime.stub(:new, runtime_factory) do
            Telemetry.configure(original)
          end
        end
      end

      assert_equal({ namespace: 'example', runtime: }, configured.client_options)
      assert_same original_plugin, configured.plugins.first
      assert_instance_of Temporalio::SimplePlugin, configured.plugins.last
      assert_same original_hook, configured.shutdown_hooks.first
      assert runtime_options.fetch(:telemetry).metrics.opentelemetry
      [1.5, 0, 0.5].each { |remaining| configured.shutdown_hooks.last.call(remaining) }
      assert_equal [1.5, 0.5], budgets
      assert_equal({ namespace: 'example' }, original.client_options)
      assert_equal [original_plugin], original.plugins
      assert_equal [original_hook], original.shutdown_hooks
    end
  end
end
