# frozen_string_literal: true

require 'temporalio/activity'

module AsyncActivity
  module MyActivities
    # Fake database client
    class MyDatabaseClient
      def select_value(table)
        "some-db-value from table #{table}"
      end
    end

    # Stateful activity that is created only once by worker creation code
    class SelectFromDatabase < Temporalio::Activity::Definition
      def initialize(db_client)
        @db_client = db_client
      end

      def execute(table)
        @db_client.select_value(table)
      end
    end

    # Stateless activity that is passed as class to worker creation code,
    # thereby instantiating every attempt
    class AppendSuffix < Temporalio::Activity::Definition
      def execute(append_to)
        puts "#{append_to} <appended-value>"
      end
    end

    class ExecuteAsyncOperation < Temporalio::Activity::Definition
      def execute(value)
        puts "#{value} <asynchronous-operation> with token #{Temporalio::Activity::Context.current.info.task_token}"
        raise Temporalio::Activity::CompleteAsyncError
      end
    end
  end
end
