# frozen_string_literal: true

require 'test'
require 'activity_worker/activity'
require 'temporalio/testing'

module ActivityWorker
  class ActivityWorkerTest < Test
    def test_activity
      env = Temporalio::Testing::ActivityEnvironment.new
      assert_equal 'Hello, SomeTestUser!', env.run(ActivityWorker::SayHelloActivity, 'SomeTestUser')
    end
  end
end
