# frozen_string_literal: true

require 'temporalio/activity'

module OpenTelemetry
  class ComposeGreetingActivity < Temporalio::Activity::Definition
    def initialize(tracer)
      @tracer = tracer
    end

    def execute(name)
      # Capture start time for histogram metric later
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Run activity in our own span. Most users will not need to create their own spans in activities, they will just
      # rely on the default spans implicitly created. This is just a sample to show it can be done.
      @tracer.in_span('my-activity-span', attributes: { 'my-group-attr' => 'simple-activities' }) do
        # Sleep for a second, then return
        sleep(1)
        "Hello, #{name}!"
      ensure
        # Custom metrics can be created inside activities
        Temporalio::Activity::Context.current.metric_meter
                                     .create_metric(:histogram, 'my-activity-histogram', value_type: :duration)
                                     .with_additional_attributes({ 'my-group-attr' => 'simple-activities' })
                                     .record(Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time)
      end
    end
  end
end
