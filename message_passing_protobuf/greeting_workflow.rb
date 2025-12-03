# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'get_greetings'
require_relative 'generated/temporal/message_passing_protobuf/v1/workflows_pb'

module MessagePassingProtobuf
  # A workflow that that returns a greeting in one of multiple supported languages.
  #
  # It exposes a query to obtain the current language, a signal to approve the workflow so that it is allowed to return
  # its result, and two updates for changing the current language and receiving the previous language in response.
  #
  # One of the update handlers only mutates and returns local workflow state; the other update handler executes an
  # activity which calls a remote service, giving access to language translations which are not available in local
  # workflow state.
  class GreetingWorkflow < Temporalio::Workflow::Definition
    workflow_query
    def language
      @state.language
    end

    workflow_init
    def initialize(input)
      # input is a Temporal::MessagePassingProtobuf::V1::StartGreetingRequest protobuf message
      @state = Temporal::MessagePassingProtobuf::V1::GreetingStateResponse.new(
        args: input,
        language: input.language,
        approval: nil,
        supported_greetings: [],
      )
    end

    def execute(input)

      unless @state.supported_greetings.size > 0
        # first time we will load the greetings from the supported_greetings
        request = Temporal::MessagePassingProtobuf::V1::GetGreetingsRequest.new(languages: @state.args.supported_languages.to_a)
        response = Temporalio::Workflow.execute_local_activity(
          GetGreetings, request, start_to_close_timeout: 10
        )
        @state.supported_greetings = response.greetings
      end
      # In addition to waiting for the `approve` signal, we also wait for all handlers to finish. Otherwise, the
      # workflow might return its result while an async set_language_using_activity update is in progress.
      Temporalio::Workflow.wait_condition { !@state.approval.nil? && Temporalio::Workflow.all_handlers_finished? }

      # Find the first greeting that matches the current language
      greeting = get_current_greeting
      greeting&.greeting
    end

    def get_current_greeting
      get_greeting(@state.language)
    end

    def get_greeting(language)
      @state.supported_greetings.find { |g| g.language == language }
    end

    workflow_query
    def get_state(_input = nil)
      @state
    end

    workflow_signal
    def approve(input)
      @state.approval = Temporal::MessagePassingProtobuf::V1::Approval.new(
        approver_name: input.name
      )
    end

    workflow_update
    def set_language(cmd)
      # rubocop:disable Naming/AccessorMethodName
      # An update handler can mutate the workflow state and return a value.
      prev = @state.language
      @state.language = cmd.language
      prev
    end

    workflow_update_validator(:set_language)
    def validate_set_language(cmd)
      valid = @state.supported_greetings.find { |g| g.language == cmd.language }
      # In an update validator you raise any exception to reject the update.
      raise "#{cmd.language} is not supported" unless valid
    end

    workflow_update
    def support_language(input)
      # Call an activity if it's not there.
      supported = get_greeting(input.language)
      unless supported
        # We use a mutex so that, if this handler is executed multiple times, each execution can schedule the activity
        # only when the previously scheduled activity has completed. This ensures that multiple calls to
        # apply_language_with_lookup are processed in order.
        @apply_language_mutex ||= Temporalio::Workflow::Mutex.new
        @apply_language_mutex.synchronize do
          request = Temporal::MessagePassingProtobuf::V1::GetGreetingsRequest.new(languages: [input.language])

          # returns Temporal::MessagePassingProtobuf::V1::GetGreetingsResponse
          response = Temporalio::Workflow.execute_activity(
            GetGreetings, request, start_to_close_timeout: 10
          )
          # The requested language might not be supported by the remote service. If so, we raise ApplicationError, which
          # will fail the update. The WorkflowExecutionUpdateAccepted event will still be added to history. (Update
          # validators can be used to reject updates before any event is written to history, but they cannot be async,
          # and so we cannot use an update validator for this purpose.)
          raise Temporalio::Error::ApplicationError, "Greeting service does not support #{input.language}" if response.greetings.empty?

          @state.supported_greetings.concat(response.greetings.to_a)
        end
      end

      if input.set_language
        set_language(Temporal::MessagePassingProtobuf::V1::SetLanguageRequest.new(language: input.language))
      else
        @state.language # Return current language if not setting
      end
    end
  end
end
