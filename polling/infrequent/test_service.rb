require 'temporalio/activity'

# A mock external service with simulated errors.
module TestService

  @attempts = Hash.new(0)
  ERROR_ATTEMPTS = 5

  ComposeGreetingInput = Struct.new(:greeting, :name)

  def get_service_result(input)
    workflow_id = Temporalio::Activity.info.workflow_id
    @attempts[workflow_id] += 1

    puts "Attempt #{@attempts[workflow_id]} of #{ERROR_ATTEMPTS} to invoke service"

    if @attempts[workflow_id] == ERROR_ATTEMPTS
      "#{input.greeting}, #{input.name}!"
    end
    raise Temporalio::Error::ApplicationError.new(
      'service is down',
      category: Temporalio::Error::ApplicationError::Category::BENIGN
    )
  end
end 