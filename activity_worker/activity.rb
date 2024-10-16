# frozen_string_literal: true

require 'temporalio/activity'

module ActivityWorker
  # Activity is a class with execute implemented
  class SayHelloActivity < Temporalio::Activity
    def execute(name)
      "Hello, #{name}!"
    end
  end
end
