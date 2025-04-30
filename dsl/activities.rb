# frozen_string_literal: true

require 'temporalio/activity'

module Dsl
  module Activities
    class Activity1 < Temporalio::Activity::Definition
      def execute(arg)
        Temporalio::Activity::Context.current.logger.info("Executing activity1 with arg: #{arg}")
        "[result from activity1: #{arg}]"
      end
    end

    class Activity2 < Temporalio::Activity::Definition
      def execute(arg)
        Temporalio::Activity::Context.current.logger.info("Executing activity2 with arg: #{arg}")
        "[result from activity2: #{arg}]"
      end
    end

    class Activity3 < Temporalio::Activity::Definition
      def execute(arg1, arg2)
        Temporalio::Activity::Context.current.logger.info("Executing activity3 with args: #{arg1} and #{arg2}")
        "[result from activity3: #{arg1} #{arg2}]"
      end
    end

    class Activity4 < Temporalio::Activity::Definition
      def execute(arg)
        Temporalio::Activity::Context.current.logger.info("Executing activity4 with arg: #{arg}")
        "[result from activity4: #{arg}]"
      end
    end

    class Activity5 < Temporalio::Activity::Definition
      def execute(arg1, arg2)
        Temporalio::Activity::Context.current.logger.info("Executing activity5 with args: #{arg1} and #{arg2}")
        "[result from activity5: #{arg1} #{arg2}]"
      end
    end
  end
end
