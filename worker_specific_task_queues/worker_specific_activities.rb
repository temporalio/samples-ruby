# frozen_string_literal: true

require 'digest'
require 'logger'
require 'net/http'
require 'tempfile'
require 'temporalio/activity'
require 'uri'

module WorkerSpecificTaskQueues
  module Activities
    class DownloadFileActivity < Temporalio::Activity::Definition
      def execute(url)
        # Simulate slow activity
        sleep(3)

        # Download file using block syntax for automatic cleanup
        temp_path = nil
        Tempfile.open do |file|
          Temporalio::Activity::Context.current.logger.info("Downloading #{url} to #{file.path}")
          file.write(Net::HTTP.get(URI(url)))
          temp_path = file.path
        end

        temp_path
      end
    end

    class WorkOnFileActivity < Temporalio::Activity::Definition
      def execute(file_path)
        # Simulate slow activity
        sleep(3)

        # Calculate checksum to simulate work
        checksum = Digest::SHA256.file(file_path).hexdigest
        Temporalio::Activity::Context.current.logger.info("Did some work on #{file_path}, checksum: #{checksum}")

        nil
      end
    end

    class CleanupFileActivity < Temporalio::Activity::Definition
      def execute(file_path)
        # Simulate slow activity
        sleep(3)

        Temporalio::Activity::Context.current.logger.info("Removing #{file_path}")
        File.unlink(file_path)

        nil
      end
    end
  end
end
