# frozen_string_literal: true

require 'temporalio/activity'
require_relative 'test_service'

module InfrequentPolling
  class ComposeGreetingActivity < Temporalio::Activity::Definition
    def execute(input)
      activity_info = Temporalio::Activity::Context.current.info
      TestService.get_service_result(input, activity_info)
    rescue TestService::TestServiceError => e
      raise Temporalio::Error::ApplicationError.new(
        e.message,
        category: Temporalio::Error::ApplicationError::Category::BENIGN
      )
    end
  end
end