# frozen_string_literal: true

require 'temporalio/contrib/aws/lambda_worker'
require_relative 'greeting_workflow'

module AwsLambda
  VERSION = Temporalio::WorkerDeploymentVersion.new(
    deployment_name: ENV.fetch('TEMPORAL_DEPLOYMENT_NAME'),
    build_id: ENV.fetch('TEMPORAL_WORKER_BUILD_ID')
  )
  options = Temporalio::Contrib::Aws::LambdaWorker::Options.new(
    workflows: [GreetingWorkflow], activities: [GreetingActivity]
  )
  if ENV['TEMPORAL_LAMBDA_TELEMETRY'] == '1'
    require_relative 'telemetry'
    options = Telemetry.configure(options)
  end
  HANDLER = Temporalio::Contrib::Aws::LambdaWorker.define(
    VERSION,
    options:
  )
end

def lambda_handler(event:, context:)
  AwsLambda::HANDLER.call(event:, context:)
end
