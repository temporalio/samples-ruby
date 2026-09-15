# frozen_string_literal: true

require 'temporalio/activity'

module Timer
  module MyActivities
    class Charge < Temporalio::Activity::Definition
      def execute(user_id)
        "charge successful for #{user_id}"
      end
    end
  end
end
