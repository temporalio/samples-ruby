# frozen_string_literal: true

require 'temporalio/activity'

# A mock external service with simulated errors.
module TestService
  class TestServiceError < StandardError; end

  @attempts = Hash.new(0)
  ERROR_ATTEMPTS = 5

  ComposeGreetingInput = Struct.new(:greeting, :name)

  def get_service_result(input, activity_info)
    workflow_id = activity_info.workflow_id
    @attempts[workflow_id] ||= 0
    @attempts[workflow_id] += 1

    puts "Attempt #{@attempts[workflow_id]} of #{ERROR_ATTEMPTS} to invoke service"

    raise TestServiceError, 'service is down' unless @attempts[workflow_id] == ERROR_ATTEMPTS

    "#{input['greeting']}, #{input['name']}!"
  end
  module_function :get_service_result
end 