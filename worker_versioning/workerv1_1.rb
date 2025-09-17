# frozen_string_literal: true

require_relative 'workflows'
require_relative 'activities'
require_relative 'constants'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require 'temporalio/worker/deployment_options'
require 'temporalio/worker_deployment_version'

module WorkerVersioning
  module WorkerV1Dot1
    def self.run_async(client)
      worker = Temporalio::Worker.new(
        client: client,
        task_queue: WorkerVersioning::Constants::TASK_QUEUE,
        workflows: [WorkerVersioning::Workflows::AutoUpgradingWorkflowV1b,
                    WorkerVersioning::Workflows::PinnedWorkflowV1],
        activities: [WorkerVersioning::Activities::SomeActivity,
                     WorkerVersioning::Activities::SomeIncompatibleActivity],
        deployment_options: Temporalio::Worker::DeploymentOptions.new(
          version: Temporalio::WorkerDeploymentVersion.new(
            deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME,
            build_id: '1.1'
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

  client = Temporalio::Client.connect(
    'localhost:7233',
    'default',
    logger: logger
  )

  logger.info('Starting worker v1.1 (build 1.1)')
  WorkerVersioning::WorkerV1Dot1.run_async(client)
end
