# frozen_string_literal: true

require 'temporalio/client/interceptor'
require 'temporalio/worker/interceptor'

module ContextPropagation
  class Interceptor
    include Temporalio::Client::Interceptor
    include Temporalio::Worker::Interceptor::Workflow
    include Temporalio::Worker::Interceptor::Activity

    def initialize(*keys_to_propagate)
      @keys_to_propagate = keys_to_propagate
    end

    def intercept_client(next_interceptor)
      ClientOutbound.new(self, next_interceptor)
    end

    def intercept_workflow(next_interceptor)
      WorkflowInbound.new(self, next_interceptor)
    end

    def intercept_activity(next_interceptor)
      ActivityInbound.new(self, next_interceptor)
    end

    def context_to_headers(input)
      @keys_to_propagate.each do |key|
        value = Thread.current[key]
        input.headers[key.to_s] = value unless value.nil?
      end
    end

    def with_context_from_headers(input)
      # Grab all original values
      orig_values = @keys_to_propagate.map { |key| [key, Thread.current[key]] }
      # Replace values, even if they are nil
      @keys_to_propagate.each { |key| Thread.current[key] = input.headers[key.to_s] }
      begin
        yield
      ensure
        # Put them all back, even if they were nil
        orig_values.each { |key, val| Thread.current[key] = val }
      end
    end

    class ClientOutbound < Temporalio::Client::Interceptor::Outbound
      def initialize(root, next_interceptor)
        super(next_interceptor)
        @root = root
      end

      def start_workflow(input)
        @root.context_to_headers(input)
        super
      end

      def signal_workflow(input)
        @root.context_to_headers(input)
        super
      end

      def query_workflow(input)
        @root.context_to_headers(input)
        super
      end

      def start_workflow_update(input)
        @root.context_to_headers(input)
        super
      end
    end

    class WorkflowInbound < Temporalio::Worker::Interceptor::Workflow::Inbound
      def initialize(root, next_interceptor)
        super(next_interceptor)
        @root = root
      end

      def init(outbound)
        super(WorkflowOutbound.new(@root, outbound))
      end

      def execute(input)
        @root.with_context_from_headers(input) { super }
      end

      def handle_signal(input)
        @root.with_context_from_headers(input) { super }
      end

      def handle_query(input)
        @root.with_context_from_headers(input) { super }
      end

      def validate_update(input)
        @root.with_context_from_headers(input) { super }
      end

      def handle_update(input)
        @root.with_context_from_headers(input) { super }
      end
    end

    class WorkflowOutbound < Temporalio::Worker::Interceptor::Workflow::Outbound
      def initialize(root, next_interceptor)
        super(next_interceptor)
        @root = root
      end

      def execute_activity(input)
        @root.context_to_headers(input)
        super
      end

      def execute_local_activity(input)
        @root.context_to_headers(input)
        super
      end

      def signal_child_workflow(input)
        @root.context_to_headers(input)
        super
      end

      def signal_external_workflow(input)
        @root.context_to_headers(input)
        super
      end

      def start_child_workflow(input)
        @root.context_to_headers(input)
        super
      end
    end

    class ActivityInbound < Temporalio::Worker::Interceptor::Activity::Inbound
      def initialize(root, next_interceptor)
        super(next_interceptor)
        @root = root
      end

      def execute(input)
        @root.with_context_from_headers(input) { super }
      end
    end
  end
end
