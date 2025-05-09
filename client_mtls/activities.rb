# frozen_string_literal: true

require 'temporalio/activity'

module ClientMtls
  module Activities
    # Simple activity definition following SDK patterns
    class ComposeGreeting < Temporalio::Activity::Definition
      def execute(greeting, name)
        "#{greeting}, #{name}!"
      end
    end
  end
end
