# frozen_string_literal: true

require 'temporalio/workflow'

module Encryption
  class MyWorkflow < Temporalio::Workflow::Definition
    def execute(name)
      "Hello, #{name}!"
    end
  end
end
