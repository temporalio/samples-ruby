# frozen_string_literal: true

require 'temporalio/activity'

module ActivityHeartbeating
  module MyActivities
    # Activity that demonstrates progress tracking with heartbeating and cancellation
    class FakeProgress < Temporalio::Activity::Definition
      def execute(sleep_interval = 1.0)
        context = Temporalio::Activity::Context.current

        begin
          # Allow for resuming from heartbeat details if available
          starting_point = context.info.heartbeat_details.first || 1

          context.logger.info("Starting activity at progress: #{starting_point}")

          (starting_point..100).each do |progress|
            # Sleep for the interval - checking cancellation after sleep
            sleep(sleep_interval)

            context.logger.info("Progress: #{progress}")
            context.heartbeat(progress)
          end

          context.logger.info('Fake progress activity completed')
        rescue Temporalio::Error::CanceledError
          # This catches the cancel just for demonstration, you usually don't want to catch it
          context.logger.info('Handling cancellation')
          raise # Re-raise to properly cancel the activity
        end
      end
    end
  end
end
