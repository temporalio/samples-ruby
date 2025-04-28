# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'
require 'temporalio/workflow'
require_relative 'say_hello_activity'

module SorbetGeneric
  class SayHelloWorkflow < Temporalio::Workflow::Definition
    extend T::Sig
    extend T::Generic

    #### WORKFLOW EXECUTE ####

    Input = type_member { { fixed: T.untyped } } # Adding a fixed untyped parameter since Sorbet requires all type args
    Output = type_member { { fixed: String } }

    # Since Sorbet does not let us change arity, we have to add an ignored parameter instead of no parameter
    sig { override.params(_: Input).returns(String) }
    def execute(_ = nil)
      Temporalio::Workflow.wait_condition { @complete_with }
    ensure
      @completed = T.let(true, T.nilable(T::Boolean))
    end

    #### WORKFLOW SIGNAL ####

    # This represents the class method created by workflow_signal and therefore needs to be defined before
    # workflow_signal since that will re-define the method. We have to use without-runtime because `[]` is not defined
    # on the definition class at runtime.
    T::Sig::WithoutRuntime.sig { returns(Temporalio::Workflow::Definition::Signal[String]) }
    def self.complete = T.unsafe(nil)

    workflow_signal
    T::Sig::WithoutRuntime.sig { params(value: String).void } # Disabling runtime due to https://github.com/sorbet/sorbet/issues/8592
    def complete(value)
      @complete_with = T.let(value, T.nilable(String))
    end

    #### WORKFLOW QUERY ####

    # This represents the class method created by workflow_query and therefore needs to be defined before workflow_query
    # since that will re-define the method. We have to use without-runtime because `[]` is not defined on the definition
    # class at runtime.
    T::Sig::WithoutRuntime.sig { returns(Temporalio::Workflow::Definition::Query[T.untyped, T.nilable(T::Boolean)]) }
    def self.completed = T.unsafe(nil)

    # Since Sorbet does not support creating a sig without a method or an attr_reader, we cannot use
    # workflow_query_attr_reader which fails if the method is already defined (to prevent mistakes), so we have to make
    # a workflow_query explicitly
    workflow_query
    T::Sig::WithoutRuntime.sig { returns(T.nilable(T::Boolean)) } # Disabling runtime sig due to https://github.com/sorbet/sorbet/issues/8592
    def completed # rubocop:disable Style/TrivialAccessors
      @completed
    end

    #### WORKFLOW UPDATE ####

    # This represents the class method created by workflow_update and therefore needs to be defined before
    # workflow_update since that will re-define the method. We have to use without-runtime because `[]` is not defined
    # on the definition class at runtime.
    T::Sig::WithoutRuntime.sig { returns(Temporalio::Workflow::Definition::Update[String, String]) }
    def self.say_hello
      T.unsafe(nil)
    end

    workflow_update
    T::Sig::WithoutRuntime.sig { params(name: String).returns(String) } # Disabling runtime sig due to https://github.com/sorbet/sorbet/issues/8592
    def say_hello(name)
      # Run an activity that accepts a string and returns a string
      result = Temporalio::Workflow.execute_activity(
        SayHelloActivity,
        # If this was changed to be an integer, type checking would fail
        name,
        start_to_close_timeout: 5 * 60 # 5 minutes
      )
      Temporalio::Workflow.logger.info("Activity result: #{result}")

      # T.reveal_type(result) # The result is properly typed as a String
      result
    end
  end
end
