require 'temporalio/activity'
require_relative './test_service'

module InfrequentPolling
  class ComposeGreetingActivity < Temporalio::Activity::Definition
    def execute(input)
      TestService.get_service_result(input)
    end
  end
end