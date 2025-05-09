ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "securerandom"
require "temporal_client"
require "temporalio/client"
require "temporalio/testing"
require "temporalio/worker"
require "workflows/shopping_cart_workflow"

module TestHelper
  def with_worker_running
    # Create a worker on a random task queue to run our workflow and activities
    raise "Task queue already obtained lazily" if TemporalClient.task_queue?
    worker = Temporalio::Worker.new(
      client: TemporalClient.instance,
      task_queue: "tq-#{SecureRandom.uuid}",
      activities: [
        Workflows::ShoppingCartActivities::FetchProducts,
        Workflows::ShoppingCartActivities::PersistCompletedOrder,
        # Use our mock
        MockApplyPaymentActivity
      ],
      workflows: [ Workflows::ShoppingCartWorkflow ]
    )
    worker.run do
      TemporalClient.task_queue = worker.task_queue
      yield worker
    ensure
      TemporalClient.task_queue = nil
    end
  end

  class MockApplyPaymentActivity < Temporalio::Activity::Definition
    activity_name :ApplyPayment

    def execute(input)
      "mock-payment-capture-id"
    end
  end
end

module ActiveSupport
  class TestCase
    include TestHelper

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

module ActionDispatch
  class IntegrationTest
    include TestHelper

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

# Start a local server, set the global client with that client, and shutdown server on complete
Temporalio::Testing::WorkflowEnvironment.start_local(logger: Rails.logger).tap do |env|
  Minitest.after_run { env.shutdown }
  TemporalClient.instance = env.client
end
