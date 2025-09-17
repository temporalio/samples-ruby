# frozen_string_literal: true

require 'temporalio/activity'

module WorkerVersioning
  class SomeActivity < Temporalio::Activity::Definition
    def execute(called_by)
      "some_activity called by #{called_by}"
    end
  end

  class SomeIncompatibleActivity < Temporalio::Activity::Definition
    def execute(input_data)
      "some_incompatible_activity called by #{input_data['called_by']} with #{input_data['more_data']}"
    end
  end
end
