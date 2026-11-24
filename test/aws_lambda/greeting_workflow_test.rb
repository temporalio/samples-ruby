# frozen_string_literal: true

require 'test'
require 'aws_lambda/greeting_workflow'
require 'securerandom'
require 'temporalio/testing'
require 'temporalio/worker'

module AwsLambda
  class GreetingWorkflowTest < Test
    def test_workflow
      Temporalio::Testing::WorkflowEnvironment.start_local do |env|
        worker = Temporalio::Worker.new(
          client: env.client,
          task_queue: "lambda-sample-#{SecureRandom.uuid}",
          workflows: [GreetingWorkflow],
          activities: [GreetingActivity]
        )
        worker.run do
          assert_equal(
            'Hello, Ruby!',
            env.client.execute_workflow(
              GreetingWorkflow, 'Ruby', id: "lambda-greeting-#{SecureRandom.uuid}", task_queue: worker.task_queue
            )
          )
        end
      end
    end
  end
end
