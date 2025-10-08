# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'updatable_timer'

module UpdatableTimer
  class UpdatableTimerWorkflow < Temporalio::Workflow::Definition
    def execute(wake_up_time)
      @timer = UpdatableTimer.new(Time.at(Rational(wake_up_time)))
      @timer.sleep
    end

    workflow_query
    def wake_up_time
      Temporalio::Workflow.logger.info('get_wake_up_time')
      @timer.wake_up_time.to_r
    end

    workflow_signal
    def update_wake_up_time(wake_up_time)
      wake_up_time = Time.at(Rational(wake_up_time))
      Temporalio::Workflow.logger.info("update_wake_up_time: #{wake_up_time}")
      @timer.wake_up_time = wake_up_time
    end
  end
end
