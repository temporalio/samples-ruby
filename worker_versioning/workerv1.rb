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

  # Create worker v1
  worker = Temporalio::Worker.new(
    client: client,
    task_queue: WorkerVersioning::TASK_QUEUE,
    workflows: [WorkerVersioning::AutoUpgradingWorkflowV1, WorkerVersioning::PinnedWorkflowV1],
    activities: [WorkerVersioning::SomeActivity, WorkerVersioning::SomeIncompatibleActivity],
    deployment_options: Temporalio::Worker::DeploymentOptions.new(
      version: Temporalio::WorkerDeploymentVersion.new(
        deployment_name: WorkerVersioning::DEPLOYMENT_NAME,
        build_id: '1.0'
      ),
      use_worker_versioning: true
    )
  )

  logger.info('Starting worker v1 (build 1.0)')
  worker.run(shutdown_signals: ['SIGINT'])
rescue StandardError => e
  logger.error("Worker failed: #{e}")
  raise
end

main
