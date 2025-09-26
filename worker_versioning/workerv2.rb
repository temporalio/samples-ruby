# frozen_string_literal: true

require_relative 'workflows'
require_relative 'activities'
require_relative 'constants'
require 'logger'
require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/worker'
require 'temporalio/worker/deployment_options'
require 'temporalio/worker_deployment_version'

module WorkerVersioning
  module WorkerV2
    def self.run_async(client)
      worker = Temporalio::Worker.new(
        client: client,
        task_queue: WorkerVersioning::Constants::TASK_QUEUE,
        workflows: [WorkerVersioning::Workflows::AutoUpgradingWorkflowV1b,
                    WorkerVersioning::Workflows::PinnedWorkflowV2],
        activities: [WorkerVersioning::Activities::SomeActivity,
                     WorkerVersioning::Activities::SomeIncompatibleActivity],
        deployment_options: Temporalio::Worker::DeploymentOptions.new(
          version: Temporalio::WorkerDeploymentVersion.new(
            deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME,
            build_id: '2.0'
          ),
          use_worker_versioning: true
        )
      )
      worker.run
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stdout, level: Logger::INFO)

  # Load config and apply defaults
  positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
  positional_args = ['localhost:7233', 'default'] if positional_args.empty?
  keyword_args[:logger] = logger

  client = Temporalio::Client.connect(*positional_args, **keyword_args)

  logger.info('Starting worker v2 (build 2.0)')
  WorkerVersioning::WorkerV2.run_async(client)
end
