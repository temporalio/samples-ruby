# frozen_string_literal: true

require 'temporalio/activity'
require_relative 'test_service'

module Polling
  module Frequent
    class ComposeGreetingActivity < Temporalio::Activity::Definition
      def execute(input)
        loop do
          activity_info = Temporalio::Activity::Context.current.info
          begin
            return TestService.get_service_result(input, activity_info)
          rescue TestService::TestServiceError
            Temporalio::Activity::Context.current.logger.info('Test service was down')
          end
          Temporalio::Activity::Context.current.heartbeat
          sleep 1
        end
      end
    end
  end
end
