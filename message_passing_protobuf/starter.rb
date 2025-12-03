# frozen_string_literal: true

# Add generated protobuf directory to load path
$LOAD_PATH.unshift(File.expand_path('generated', __dir__))

require 'temporalio/client'
require 'temporalio/env_config'
require 'securerandom'
require_relative 'greeting_workflow'
require_relative 'generated/temporal/message_passing_protobuf/v1/workflows_pb'

# Load config and apply defaults
args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
args[0] ||= 'localhost:7233' # Default address
args[1] ||= 'default' # Default namespace

# Create custom data converter with BinaryProtobuf before JSONProtobuf for UTF-8 support
payload_converter = Temporalio::Converters::PayloadConverter::Composite.new(
  Temporalio::Converters::PayloadConverter::BinaryNull.new,
  Temporalio::Converters::PayloadConverter::BinaryPlain.new,
  Temporalio::Converters::PayloadConverter::BinaryProtobuf.new,  # Binary first for UTF-8 support
  Temporalio::Converters::PayloadConverter::JSONProtobuf.new,
  Temporalio::Converters::PayloadConverter::JSONPlain.new
)
data_converter = Temporalio::Converters::DataConverter.new(payload_converter: payload_converter)

# Create a client
client = Temporalio::Client.connect(*args, **kwargs, data_converter: data_converter,logger: Logger.new($stdout, level: Logger::INFO))

# Start the workflow
puts 'Starting workflow'
handle = client.start_workflow(
  MessagePassingProtobuf::GreetingWorkflow,
  Temporal::MessagePassingProtobuf::V1::StartGreetingRequest.new(
    timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i, nanos: Time.now.nsec),
    language: 'english',
    supported_languages: ['english', 'chinese']
  ),
  id: "wf-#{SecureRandom.uuid}",
  task_queue: 'message-passing-protobuf-sample',
)

# Send a query
state = handle.query(MessagePassingProtobuf::GreetingWorkflow.get_state)
puts "Supported languages: #{state.args.supported_languages}"

# Execute an update
prev_language = handle.execute_update(MessagePassingProtobuf::GreetingWorkflow.set_language,
                                      Temporal::MessagePassingProtobuf::V1::SetLanguageRequest.new(
  language: 'chinese',
  ))
state = handle.query(MessagePassingProtobuf::GreetingWorkflow.get_state)
puts "Language changed: #{prev_language} -> #{state.language}"

# Start an update and then wait for it to complete
update_handle = handle.start_update(
  MessagePassingProtobuf::GreetingWorkflow.support_language,
  Temporal::MessagePassingProtobuf::V1::SupportLanguageRequest.new(
    language: 'arabic',
    set_language: true,
    ),
  wait_for_stage: Temporalio::Client::WorkflowUpdateWaitStage::ACCEPTED
)
prev_language = update_handle.result
state = handle.query(MessagePassingProtobuf::GreetingWorkflow.get_state)
puts "Language changed: #{prev_language} -> #{state.language}"

# Send signal and wait for workflow to complete
handle.signal(MessagePassingProtobuf::GreetingWorkflow.approve, Temporal::MessagePassingProtobuf::V1::ApproveForReleaseRequest.new(
  name: 'John Q. Approver'))

puts "Workflow result: #{handle.result}"
