# frozen_string_literal: true

require 'encryption/codec'
require 'encryption/codec_server'
require 'encryption/my_workflow'
require 'net/http'
require 'puma'
require 'socket'
require 'temporalio/api'
require 'temporalio/testing'
require 'temporalio/worker'
require 'test'

module Encryption
  class CodecTest < Test
    def test_codec_and_server
      # Run a workflow with the codec
      Temporalio::Testing::WorkflowEnvironment.start_local(
        data_converter: Temporalio::Converters::DataConverter.new(payload_codec: Codec.new)
      ) do |env|
        # Run worker until completion of the block
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "tq-#{SecureRandom.uuid}",
          workflows: [MyWorkflow],
          workflow_payload_codec_thread_pool: Temporalio::Worker::ThreadPool.default
        )
        handle = worker.run do
          # Start workflow
          handle = env.client.start_workflow(
            MyWorkflow, 'some-name',
            id: "wf-#{SecureRandom.uuid}", task_queue: worker.task_queue
          )

          # Confirm result is as expected from the client since it has the codec
          assert_equal('Hello, some-name!', handle.result)
          handle
        end

        # Now get events and confirm both the input and output are encrypted
        history = handle.fetch_history
        start_event_attrs = history.events.find(&:workflow_execution_started_event_attributes)
                                   .workflow_execution_started_event_attributes
        assert_equal('binary/encrypted'.b, start_event_attrs.input.payloads.first.metadata['encoding'])
        complete_event_attrs = history.events.find(&:workflow_execution_completed_event_attributes)
                                      .workflow_execution_completed_event_attributes
        assert_equal('binary/encrypted'.b, complete_event_attrs.result.payloads.first.metadata['encoding'])

        # Let's also run the codec server and run the payloads through them...

        # First, find a free port
        sock = TCPServer.new('127.0.0.1', 0)
        port = sock.addr[1]
        sock.close

        # Now start codec server
        server = Puma::Server.new(Encryption::CodecServer.new)
        server.add_tcp_listener('127.0.0.1', port)
        server.run

        # Make HTTP call for decode
        resp = Net::HTTP.post(
          URI("http://127.0.0.1:#{port}/decode"),
          complete_event_attrs.result.to_json,
          'Content-Type' => 'application/json'
        )
        decoded = Temporalio::Api::Common::V1::Payloads.decode_json(resp.body)
        assert_equal('"Hello, some-name!"', decoded.payloads.first.data)

        # Make HTTP call for encode
        resp = Net::HTTP.post(
          URI("http://127.0.0.1:#{port}/encode"),
          decoded.to_json,
          'Content-Type' => 'application/json'
        )
        encoded = Temporalio::Api::Common::V1::Payloads.decode_json(resp.body)
        assert_equal('binary/encrypted', encoded.payloads.first.metadata['encoding'])
      ensure
        server&.stop(true)
      end
    end
  end
end
