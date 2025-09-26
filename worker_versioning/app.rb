# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/env_config'
require 'temporalio/api/workflowservice/v1/request_response'
require 'temporalio/worker_deployment_version'
require 'logger'
require 'securerandom'
require_relative 'constants'

def main(client = nil)
  logger = Logger.new($stdout, level: Logger::INFO)

  unless client
    # Load config and apply defaults
    positional_args, keyword_args = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
    positional_args = ['localhost:7233', 'default'] if positional_args.empty?
    keyword_args[:logger] = logger

    client = Temporalio::Client.connect(*positional_args, **keyword_args)
  end

  # Wait for v1 worker and set as current version
  logger.info(
    'Waiting for v1 worker to appear. Run `ruby worker_versioning/workerv1.rb` in another terminal'
  )
  wait_for_worker_and_make_current(client, '1.0')

  # Start auto-upgrading and pinned workflows. Importantly, note that when we start the workflows,
  # we are using a workflow type name which does *not* include the version number. We defined them
  # with versioned names so we could show changes to the code, but here when the client invokes
  # them, we're demonstrating that the client remains version-agnostic.
  auto_upgrade_workflow_id = "worker-versioning-versioning-autoupgrade_#{SecureRandom.uuid}"
  auto_upgrade_execution = client.start_workflow(
    :AutoUpgrading,
    id: auto_upgrade_workflow_id,
    task_queue: WorkerVersioning::Constants::TASK_QUEUE
  )

  pinned_workflow_id = "worker-versioning-versioning-pinned_#{SecureRandom.uuid}"
  pinned_execution = client.start_workflow(
    :Pinned,
    id: pinned_workflow_id,
    task_queue: WorkerVersioning::Constants::TASK_QUEUE
  )

  logger.info("Started auto-upgrading workflow: #{auto_upgrade_execution.id}")
  logger.info("Started pinned workflow: #{pinned_execution.id}")

  # Signal both workflows a few times to drive them
  advance_workflows(auto_upgrade_execution, pinned_execution)

  # Now wait for the v1.1 worker to appear and become current
  logger.info(
    'Waiting for v1.1 worker to appear. Run `ruby worker_versioning/workerv1_1.rb` in another terminal'
  )
  wait_for_worker_and_make_current(client, '1.1')

  # Once it has, we will continue to advance the workflows.
  # The auto-upgrade workflow will now make progress on the new worker, while the pinned one will
  # keep progressing on the old worker.
  advance_workflows(auto_upgrade_execution, pinned_execution)

  # Finally we'll start the v2 worker, and again it'll become the new current version
  logger.info(
    'Waiting for v2 worker to appear. Run `ruby worker_versioning/workerv2.rb` in another terminal'
  )
  wait_for_worker_and_make_current(client, '2.0')

  # Once it has we'll start one more new workflow, another pinned one, to demonstrate that new
  # pinned workflows start on the current version.
  pinned_workflow_2_id = "worker-versioning-versioning-pinned-2_#{SecureRandom.uuid}"
  pinned_execution_v2 = client.start_workflow(
    :Pinned,
    id: pinned_workflow_2_id,
    task_queue: WorkerVersioning::Constants::TASK_QUEUE
  )
  logger.info("Started pinned workflow v2: #{pinned_execution_v2.id}")

  # Now we'll conclude all workflows. You should be able to see in your server UI that the pinned
  # workflow always stayed on 1.0, while the auto-upgrading workflow migrated.
  [auto_upgrade_execution, pinned_execution, pinned_execution_v2].each do |handle|
    handle.signal(:do_next_signal, 'conclude')
    handle.result
  end

  logger.info('All workflows completed')
end

def advance_workflows(auto_upgrade_execution, pinned_execution)
  # Signal both workflows a few times to drive them.
  3.times do
    auto_upgrade_execution.signal(:do_next_signal, 'do-activity')
    pinned_execution.signal(:do_next_signal, 'some-signal')
  end
end

def wait_for_worker_and_make_current(client, build_id)
  target_version = Temporalio::WorkerDeploymentVersion.new(
    deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME,
    build_id: build_id
  )

  loop do
    describe_request = Temporalio::Api::WorkflowService::V1::DescribeWorkerDeploymentRequest.new(
      namespace: client.namespace,
      deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME
    )
    response = client.workflow_service.describe_worker_deployment(describe_request)

    found = response.worker_deployment_info.version_summaries.any? do |version_summary|
      version_summary.deployment_version.deployment_name == target_version.deployment_name &&
        version_summary.deployment_version.build_id == target_version.build_id
    end

    break if found

    sleep(1)
  rescue Temporalio::Error::RPCError => e
    # If not-found, wait a second and try again
    raise unless e.code == Temporalio::Error::RPCError::Code::NOT_FOUND

    sleep(1)
    next
  end

  # Once the version is available, set it as current
  set_request = Temporalio::Api::WorkflowService::V1::SetWorkerDeploymentCurrentVersionRequest.new(
    namespace: client.namespace,
    deployment_name: WorkerVersioning::Constants::DEPLOYMENT_NAME,
    version: target_version.to_canonical_string
  )
  client.workflow_service.set_worker_deployment_current_version(set_request)
end

main if __FILE__ == $PROGRAM_NAME
