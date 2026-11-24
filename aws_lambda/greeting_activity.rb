# frozen_string_literal: true

require 'temporalio/activity'

module AwsLambda
  class GreetingActivity < Temporalio::Activity::Definition
    def execute(name)
      "Hello, #{name}!"
    end
  end
end
