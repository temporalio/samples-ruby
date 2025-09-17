# frozen_string_literal: true

require_relative 'workflows'
require_relative 'activities'
require_relative 'constants'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require 'temporalio/worker/deployment_options'
require 'temporalio/worker_deployment_version'

logger = Logger.new($stdout, level: Logger::INFO)

client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: logger
)

worker = Temporalio::Worker.new(
  client: client,
  task_queue: WorkerVersioning::Constants::TASK_QUEUE,
  workflows: [WorkerVersioning::Workflows::AutoUpgradingWorkflowV1b, WorkerVersioning::Workflows::PinnedWorkflowV1],
  activities: [WorkerVersioning::Activities::SomeActivity, WorkerVersioning::Activities::SomeIncompatibleActivity],
  deployment_options: Temporalio::Worker::DeploymentOptions.new(
    version: Temporalio::WorkerDeploymentVersion.new(
      deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME,
      build_id: '1.1'
    ),
    use_worker_versioning: true
  )
)

logger.info('Starting worker v1.1 (build 1.1)')
worker.run(shutdown_signals: ['SIGINT'])
