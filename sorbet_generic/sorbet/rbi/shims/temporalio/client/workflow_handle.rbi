# typed: strict

class Temporalio::Client::WorkflowHandle
  Result = type_member(:out)

  sig do
    type_parameters(:TArg, :TResult)
      .params(
        update: Temporalio::Workflow::Definition::Update[T.type_parameter(:TArg), T.type_parameter(:TResult)],
        arg: T.type_parameter(:TArg),
        id: String,
        rpc_options: T.nilable(Temporalio::Client::RPCOptions)
      )
      .returns(T.type_parameter(:TResult))
  end
  def execute_update(
    update,
    arg = T.unsafe(nil),
    id: T.unsafe(nil),
    rpc_options: T.unsafe(nil)
  )
  end

  sig do
    type_parameters(:TArg, :TResult)
      .params(
        query: Temporalio::Workflow::Definition::Query[T.type_parameter(:TArg), T.type_parameter(:TResult)],
        arg: T.type_parameter(:TArg),
        reject_condition: T.nilable(Integer),
        rpc_options: T.nilable(Temporalio::Client::RPCOptions)
      )
      .returns(T.type_parameter(:TResult))
  end
  def query(
    query,
    arg = T.unsafe(nil),
    reject_condition: T.unsafe(nil),
    rpc_options: T.unsafe(nil)
  )
  end

  sig do
    params(follow_runs: T::Boolean, result_hint: T.untyped, rpc_options: T.nilable(Temporalio::Client::RPCOptions))
      .returns(Result)
  end
  def result(follow_runs: T.unsafe(nil), result_hint: T.unsafe(nil), rpc_options: T.unsafe(nil)); end

  sig do
    type_parameters(:TArg)
      .params(
        signal: Temporalio::Workflow::Definition::Signal[T.type_parameter(:TArg)],
        arg: T.type_parameter(:TArg),
        rpc_options: T.nilable(Temporalio::Client::RPCOptions)
      )
      .void
  end
  def signal(
    signal,
    arg = T.unsafe(nil),
    rpc_options: T.unsafe(nil)
  )
  end
end
