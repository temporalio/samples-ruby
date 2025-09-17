# frozen_string_literal: true

require 'temporalio/common_enums'
require 'temporalio/workflow'
require 'temporalio/workflow/definition'
require_relative 'activities'

module WorkerVersioning
  # AutoUpgradingWorkflowV1 will automatically move to the latest worker version. We'll be making
  # changes to it, which must be replay safe.
  #
  # Note that generally you won't want or need to include a version number in your workflow name if
  # you're using the worker versioning feature. This sample does it to illustrate changes to the
  # same code over time - but really what we're demonstrating here is the evolution of what would
  # have been one workflow definition.
  class AutoUpgradingWorkflowV1 < Temporalio::Workflow::Definition
    workflow_name :AutoUpgrading
    workflow_versioning_behavior Temporalio::VersioningBehavior::AUTO_UPGRADE

    def initialize
      @signals = []
    end

    def execute
      Temporalio::Workflow.logger.info('Changing workflow v1 started.')

      # This workflow will listen for signals from our starter, and upon each signal either run
      # an activity, or conclude execution.
      loop do
        Temporalio::Workflow.wait_condition { @signals.any? }
        signal = @signals.shift

        if signal == 'do-activity'
          Temporalio::Workflow.logger.info('Changing workflow v1 running activity')
          Temporalio::Workflow.execute_activity(
            WorkerVersioning::SomeActivity,
            'v1',
            start_to_close_timeout: 10
          )
        else
          Temporalio::Workflow.logger.info('Concluding workflow v1')
          return
        end
      end
    end

    workflow_signal
    def do_next_signal(signal)
      @signals << signal
    end
  end

  # AutoUpgradingWorkflowV1b represents us having made *compatible* changes to
  # AutoUpgradingWorkflowV1.
  #
  # The compatible changes we've made are:
  #   - Altering the log lines
  #   - Using the workflow.patched API to properly introduce branching behavior while maintaining
  #     compatibility
  class AutoUpgradingWorkflowV1b < Temporalio::Workflow::Definition
    workflow_name :AutoUpgrading
    workflow_versioning_behavior Temporalio::VersioningBehavior::AUTO_UPGRADE

    def initialize
      @signals = []
    end

    def execute
      Temporalio::Workflow.logger.info('Changing workflow v1b started.')

      # This workflow will listen for signals from our starter, and upon each signal either run
      # an activity, or conclude execution.
      loop do
        Temporalio::Workflow.wait_condition { @signals.any? }
        signal = @signals.shift

        if signal == 'do-activity'
          Temporalio::Workflow.logger.info('Changing workflow v1b running activity')
          if Temporalio::Workflow.patched('DifferentActivity')
            Temporalio::Workflow.execute_activity(
              WorkerVersioning::SomeIncompatibleActivity,
              WorkerVersioning::IncompatibleActivityInput.new(called_by: 'v1b', more_data: 'hello!'),
              start_to_close_timeout: 10
            )
          else
            # Note it is a valid compatible change to alter the input to an activity.
            # However, because we're using the patched API, this branch will never be
            # taken.
            Temporalio::Workflow.execute_activity(
              WorkerVersioning::SomeActivity,
              'v1b',
              start_to_close_timeout: 10
            )
          end
        else
          Temporalio::Workflow.logger.info('Concluding workflow v1b')
          break
        end
      end
    end

    workflow_signal
    def do_next_signal(signal)
      @signals << signal
    end
  end

  # PinnedWorkflowV1 demonstrates a workflow that likely has a short lifetime, and we want to always
  # stay pinned to the same version it began on.
  #
  # Note that generally you won't want or need to include a version number in your workflow name if
  # you're using the worker versioning feature. This sample does it to illustrate changes to the
  # same code over time - but really what we're demonstrating here is the evolution of what would
  # have been one workflow definition.
  class PinnedWorkflowV1 < Temporalio::Workflow::Definition
    workflow_name :Pinned
    workflow_versioning_behavior Temporalio::VersioningBehavior::PINNED

    def initialize
      @signals = []
    end

    def execute
      Temporalio::Workflow.logger.info('Pinned Workflow v1 started.')

      loop do
        Temporalio::Workflow.wait_condition { @signals.any? }
        signal = @signals.shift
        break if signal == 'conclude'
      end

      Temporalio::Workflow.execute_activity(
        WorkerVersioning::SomeActivity,
        'Pinned-v1',
        start_to_close_timeout: 10
      )
    end

    workflow_signal
    def do_next_signal(signal)
      @signals << signal
    end
  end

  # PinnedWorkflowV2 has changes that would make it incompatible with v1, and aren't protected by
  # a patch.
  class PinnedWorkflowV2 < Temporalio::Workflow::Definition
    workflow_name :Pinned
    workflow_versioning_behavior Temporalio::VersioningBehavior::PINNED

    def initialize
      @signals = []
    end

    def execute
      Temporalio::Workflow.logger.info('Pinned Workflow v2 started.')

      # Here we call an activity where we didn't before, which is an incompatible change.
      Temporalio::Workflow.execute_activity(
        WorkerVersioning::SomeActivity,
        'Pinned-v2',
        start_to_close_timeout: 10
      )

      loop do
        Temporalio::Workflow.wait_condition { @signals.any? }
        signal = @signals.shift
        break if signal == 'conclude'
      end

      # We've also changed the activity type here, another incompatible change
      Temporalio::Workflow.execute_activity(
        WorkerVersioning::SomeIncompatibleActivity,
        { called_by: 'Pinned-v2', more_data: 'hi' },
        start_to_close_timeout: 10
      )
    end

    workflow_signal
    def do_next_signal(signal)
      @signals << signal
    end
  end
end
