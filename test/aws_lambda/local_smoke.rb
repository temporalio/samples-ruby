# frozen_string_literal: true

# Run manually with the unreleased SDK against a local Temporal server, not AWS.
# See aws_lambda/README.md. Intentionally not part of the released-SDK test suite.
require 'open3'
require 'timeout'
require_relative '../../aws_lambda/lambda_function'

module AwsLambda
  SmokeContext = Data.define(:aws_request_id, :invoked_function_arn, :deadline) do
    def get_remaining_time_in_millis # rubocop:disable Naming/AccessorMethodName -- AWS Lambda context API
      [(deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)) * 1000, 0].max
    end
  end
end

2.times do |index|
  context = AwsLambda::SmokeContext.new(
    "local-#{index}", 'local-test-function', Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
  )
  starter = Thread.new do
    Timeout.timeout(18) do
      loop do
        output, error, status = Open3.capture3(
          RbConfig.ruby, File.expand_path('../../aws_lambda/starter.rb', __dir__)
        )
        if status.success?
          raise "Unexpected result: #{output.inspect}" unless output.strip == 'Hello, Ruby!'

          puts "Invocation #{index + 1} starter: #{output.strip}"
          break
        end
        # A fresh deployment cannot be pinned until its worker first polls.
        raise error unless error.match?(/Pinned version .* is not present/)

        sleep 0.2
      end
    end
  end
  result = lambda_handler(event: { 'ignored' => 'does not start a workflow' }, context: context)
  raise "Unexpected handler result: #{result.inspect}" unless result.nil?

  starter.value
  puts "Invocation #{index + 1} shut down; same handler reused"
end
