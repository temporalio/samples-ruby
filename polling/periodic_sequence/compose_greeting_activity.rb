# frozen_string_literal: true

require 'temporalio/activity'
require_relative 'test_service'

module Polling
  module PeriodicSequence
    class ComposeGreetingActivity < Temporalio::Activity::Definition
      def execute(input)
        activity_info = Temporalio::Activity::Context.current.info
        TestService.get_service_result(input, activity_info)
      end
    end
  end
end
