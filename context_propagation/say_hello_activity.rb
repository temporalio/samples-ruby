# frozen_string_literal: true

require 'temporalio/activity'

module ContextPropagation
  class SayHelloActivity < Temporalio::Activity::Definition
    def execute(name)
      Temporalio::Activity::Context.current.logger.info("Activity called by user: #{Thread.current[:my_user]}")
      "Hello, #{name}! (called by user #{Thread.current[:my_user]})"
    end
  end
end
