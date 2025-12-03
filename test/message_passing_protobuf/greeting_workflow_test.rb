# frozen_string_literal: true

require 'test'
require 'message_passing_protobuf/call_greeting_service'
require 'message_passing_protobuf/greeting_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'
require 'logger'

module MessagePassingProtobuf
  class GreetingWorkflowTest < Test
    def with_worker_running
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        # Create a logger for debugging
        logger = Logger.new($stdout)
        logger.level = Logger::DEBUG  # Set to DEBUG for detailed logs

        # Create custom data converter with BinaryProtobuf before JSONProtobuf
        payload_converter = Temporalio::Converters::PayloadConverter::Composite.new(
          Temporalio::Converters::PayloadConverter::BinaryNull.new,
          Temporalio::Converters::PayloadConverter::BinaryPlain.new,
          Temporalio::Converters::PayloadConverter::BinaryProtobuf.new,  # Binary first!
          Temporalio::Converters::PayloadConverter::JSONProtobuf.new,
          Temporalio::Converters::PayloadConverter::JSONPlain.new
        )
        data_converter = Temporalio::Converters::DataConverter.new(payload_converter: payload_converter)

        # Override the client's data converter
        client = Temporalio::Client.new(
          connection: env.client.connection,
          namespace: env.client.namespace,
          data_converter: data_converter
        )

        worker = Temporalio::Worker.new(
          client: client,
          task_queue: "tq-#{SecureRandom.uuid}",
          activities: [CallGreetingService, GetGreetings],
          workflows: [GreetingWorkflow],
          logger: logger
        )
        worker.run { yield client, worker }
      end
    end

    def test_queries
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow,
                                       Temporal::MessagePassingProtobuf::V1::StartGreetingRequest.new(
                                         language: 'english',
                                         supported_languages: ['english', 'chinese'],
                                         timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i, nanos: Time.now.nsec)
                                       ),
                                       id: "wf-#{SecureRandom.uuid}",
                                       task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)

        state = handle.query(GreetingWorkflow.get_state)
        assert_equal %w[chinese english], state.supported_greetings.map(&:language).sort
      end
    end

    def test_set_language
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow,
                                       Temporal::MessagePassingProtobuf::V1::StartGreetingRequest.new(
                                         language: 'english',
                                         supported_languages: ['english', 'chinese'],
                                         timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i, nanos: Time.now.nsec)
                                       ),
                                       id: "wf-#{SecureRandom.uuid}",
                                       task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)
        prev_language = handle.execute_update(GreetingWorkflow.set_language,
                                              Temporal::MessagePassingProtobuf::V1::SetLanguageRequest.new(language: 'chinese'))
        assert_equal 'english', prev_language
        assert_equal 'chinese', handle.query(GreetingWorkflow.language)
      end
    end

    def test_set_language_invalid
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow,
                                       Temporal::MessagePassingProtobuf::V1::StartGreetingRequest.new(
                                         language: 'english',
                                         supported_languages: ['english', 'chinese'],
                                         timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i, nanos: Time.now.nsec)
                                       ),
                                       id: "wf-#{SecureRandom.uuid}",
                                       task_queue: worker.task_queue)
        assert_equal 'english', handle.query(GreetingWorkflow.language)
        assert_raises(Temporalio::Error::WorkflowUpdateFailedError) do
          handle.execute_update(GreetingWorkflow.set_language,
                               Temporal::MessagePassingProtobuf::V1::SetLanguageRequest.new(language: 'arabic'))
        end
      end
    end

    def test_apply_language_with_lookup
      with_worker_running do |client, worker|
        handle = client.start_workflow(GreetingWorkflow,
                                       Temporal::MessagePassingProtobuf::V1::StartGreetingRequest.new(
                                         language: 'english',
                                         supported_languages: ['english', 'chinese'],
                                         timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i, nanos: Time.now.nsec)
                                       ),
                                       id: "wf-#{SecureRandom.uuid}",
                                       task_queue: worker.task_queue)
        prev_language = handle.execute_update(GreetingWorkflow.support_language,
                                              Temporal::MessagePassingProtobuf::V1::SupportLanguageRequest.new(
                                                language: 'arabic',
                                                set_language: true
                                              ))
        assert_equal 'english', prev_language
        assert_equal 'arabic', handle.query(GreetingWorkflow.language)
      end
    end
  end
end
