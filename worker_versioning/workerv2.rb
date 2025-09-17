#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'workflows'
require_relative 'activities'
require_relative 'constants'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'
require 'temporalio/worker/deployment_options'
require 'temporalio/worker_deployment_version'

def main
  logger = Logger.new($stdout, level: Logger::INFO)

  client = Temporalio::Client.connect(
    'localhost:7233',
    'default',
    logger: logger
  )

  # Create worker v2
  worker = Temporalio::Worker.new(
    client: client,
    task_queue: WorkerVersioning::TASK_QUEUE,
    workflows: [WorkerVersioning::AutoUpgradingWorkflowV1b, WorkerVersioning::PinnedWorkflowV2],
    activities: [WorkerVersioning::SomeActivity, WorkerVersioning::SomeIncompatibleActivity],
    deployment_options: Temporalio::Worker::DeploymentOptions.new(
      version: Temporalio::WorkerDeploymentVersion.new(
        deployment_name: WorkerVersioning::DEPLOYMENT_NAME,
        build_id: '2.0'
      ),
      use_worker_versioning: true
    )
  )

  logger.info('Starting worker v2 (build 2.0)')
  worker.run(shutdown_signals: ['SIGINT'])
rescue StandardError => e
  logger.error("Worker failed: #{e}")
  raise
end

main
