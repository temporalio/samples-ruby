# frozen_string_literal: true

require 'temporalio/workflow'

module UpdatableTimer
  class UpdatableTimer
    def initialize(wake_up_time)
      @wake_up_time = wake_up_time
    end

    attr_reader :wake_up_time

    def wake_up_time=(wake_up_time)
      Temporalio::Workflow.logger.info("update_wake_up_time: #{wake_up_time}")
      @wake_up_time = wake_up_time
      @wake_up_time_updated = true
    end

    def sleep
      Temporalio::Workflow.logger.info("sleep until: #{@wake_up_time}")
      loop do
        now = Temporalio::Workflow.now
        sleep_interval = @wake_up_time - now

        break if sleep_interval.negative?

        Temporalio::Workflow.logger.info("going to sleep for: #{sleep_interval}")

        begin
          @wake_up_time_updated = false
          Temporalio::Workflow.timeout(sleep_interval) do
            Temporalio::Workflow.wait_condition { @wake_up_time_updated }
          end
        rescue Timeout::Error
          break
        end
      end
      Temporalio::Workflow.logger.info('sleep_until completed')
    end
  end
end
