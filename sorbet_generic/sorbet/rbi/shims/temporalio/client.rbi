# typed: strict

class Temporalio::Client
  sig do
    type_parameters(:TArg, :TResult)
      .params(
        workflow: T::Class[Temporalio::Workflow::Definition[T.type_parameter(:TArg), T.type_parameter(:TResult)]],
        arg: T.type_parameter(:TArg),
        id: String,
        task_queue: String,
        execution_timeout: T.nilable(Numeric),
        run_timeout: T.nilable(Numeric),
        task_timeout: T.nilable(Numeric),
        id_reuse_policy: Integer,
        id_conflict_policy: Integer,
        retry_policy: T.nilable(Temporalio::RetryPolicy),
        cron_schedule: T.nilable(String),
        memo: T::Hash[T.any(String, Symbol), T.anything],
        search_attributes: T.nilable(Temporalio::SearchAttributes),
        start_delay: T.nilable(Numeric),
        request_eager_start: T::Boolean,
        rpc_options: T.nilable(Temporalio::Client::RPCOptions)
      )
      .returns(Temporalio::Client::WorkflowHandle[T.type_parameter(:TResult)])
  end
  def start_workflow(
    workflow,
    arg = T.unsafe(nil),
    id:,
    task_queue:,
    execution_timeout: T.unsafe(nil),
    run_timeout: T.unsafe(nil),
    task_timeout: T.unsafe(nil),
    id_reuse_policy: T.unsafe(nil),
    id_conflict_policy: T.unsafe(nil),
    retry_policy: T.unsafe(nil),
    cron_schedule: T.unsafe(nil),
    memo: T.unsafe(nil),
    search_attributes: T.unsafe(nil),
    start_delay: T.unsafe(nil),
    request_eager_start: T.unsafe(nil),
    rpc_options: T.unsafe(nil)
  )
  end

  class << self
    sig do
      params(
        target_host: String,
        namespace: String,
        api_key: T.nilable(String),
        tls: T.any(T::Boolean, Temporalio::Client::Connection::TLSOptions),
        data_converter: Temporalio::Converters::DataConverter,
        interceptors: T::Array[Temporalio::Client::Interceptor],
        logger: Logger,
        default_workflow_query_reject_condition: T.nilable(Integer),
        rpc_metadata: T::Hash[String, String],
        rpc_retry: Temporalio::Client::Connection::RPCRetryOptions,
        identity: String,
        keep_alive: T.nilable(Temporalio::Client::Connection::KeepAliveOptions),
        http_connect_proxy: T.nilable(Temporalio::Client::Connection::HTTPConnectProxyOptions),
        runtime: Temporalio::Runtime,
        lazy_connect: T::Boolean
      )
        .returns(Temporalio::Client)
    end
    def connect(
      target_host,
      namespace,
      api_key: T.unsafe(nil),
      tls: T.unsafe(nil),
      data_converter: T.unsafe(nil),
      interceptors: T.unsafe(nil),
      logger: T.unsafe(nil),
      default_workflow_query_reject_condition: T.unsafe(nil),
      rpc_metadata: T.unsafe(nil),
      rpc_retry: T.unsafe(nil),
      identity: T.unsafe(nil),
      keep_alive: T.unsafe(nil),
      http_connect_proxy: T.unsafe(nil),
      runtime: T.unsafe(nil),
      lazy_connect: T.unsafe(nil)
    ); end
  end
end
