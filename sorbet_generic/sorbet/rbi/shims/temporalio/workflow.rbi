# typed: strict

module Temporalio::Workflow
  class << self
    extend T::Sig

    sig do
      type_parameters(:TArg, :TResult)
        .params(
          activity: T::Class[Temporalio::Activity::Definition[T.type_parameter(:TArg), T.type_parameter(:TResult)]],
          arg: T.type_parameter(:TArg),
          task_queue: String,
          schedule_to_close_timeout: T.nilable(Numeric),
          schedule_to_start_timeout: T.nilable(Numeric),
          start_to_close_timeout: T.nilable(Numeric),
          heartbeat_timeout: T.nilable(Numeric),
          retry_policy: T.nilable(Temporalio::RetryPolicy),
          cancellation: Temporalio::Cancellation,
          cancellation_type: Integer,
          activity_id: T.nilable(String),
          disable_eager_execution: T::Boolean
        )
        .returns(T.type_parameter(:TResult))
    end
    def execute_activity(
      activity,
      arg = T.unsafe(nil),
      task_queue: T.unsafe(nil),
      schedule_to_close_timeout: T.unsafe(nil),
      schedule_to_start_timeout: T.unsafe(nil),
      start_to_close_timeout: T.unsafe(nil),
      heartbeat_timeout: T.unsafe(nil),
      retry_policy: T.unsafe(nil),
      cancellation: T.unsafe(nil),
      cancellation_type: T.unsafe(nil),
      activity_id: T.unsafe(nil),
      disable_eager_execution: T.unsafe(nil)
    )
    end

    sig do
      type_parameters(:TResult)
        .params(
          cancellation: Temporalio::Cancellation,
          block: T.proc.returns(T.nilable(T.type_parameter(:TResult)))
        )
        .returns(T.type_parameter(:TResult))
    end
    def wait_condition(cancellation: T.unsafe(nil), &block); end
  end
end
