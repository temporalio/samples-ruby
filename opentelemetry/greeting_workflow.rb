# frozen_string_literal: true

require 'temporalio/workflow'
require 'temporalio/contrib/open_telemetry'
require_relative 'compose_greeting_activity'

module OpenTelemetrySample
  class GreetingWorkflow < Temporalio::Workflow::Definition
    def initialize
      # Custom metrics can be created inside workflows. Most users will not need to create custom metrics inside
      # workflows, this just shows that it can be done.
      @my_workflow_counter = Temporalio::Workflow.metric_meter.create_metric(:counter, 'my-workflow-counter')
                                                 .with_additional_attributes({ 'my-group-attr' => 'simple-workflows' })
    end

    def execute(name)
      # Increment our custom metric
      @my_workflow_counter.record(35)

      # We can create a span in the workflow too. This is just an example to show this can be done, most users will not
      # create spans in workflows but rather rely on the defaults.
      #
      # This span is completed as soon as created because OpenTelemetry doesn't support spans that may have to be
      # completed on different machines. The span will be parented to the outer workflow span. Whether the outer span is
      # the "StartWorkflow" from the client or the "RunWorkflow" where it first ran depends on if this is replayed
      # separately from where it started. See the Ruby SDK README for more details.
      Temporalio::Contrib::OpenTelemetry::Workflow.with_completed_span(
        'my-workflow-span',
        attributes: { 'my-group-attr' => 'simple-workflows' }
      ) do
        # The span will be the parent of the span created here to start the activity
        Temporalio::Workflow.execute_activity(
          ComposeGreetingActivity,
          name, # Activity argument
          start_to_close_timeout: 5 * 60 # 5 minutes
        )
      end
    end
  end
end
