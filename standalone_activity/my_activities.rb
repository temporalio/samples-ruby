# frozen_string_literal: true

require 'temporalio/activity'

module StandaloneActivity
  module MyActivities
    class ComposeGreeting < Temporalio::Activity::Definition
      def execute(greeting, name)
        "#{greeting}, #{name}!"
      end
    end
  end
end
