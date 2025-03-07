# frozen_string_literal: true

require 'temporalio/activity'

module CoinbaseRuby
  class TemporalActivity < Temporalio::Activity::Definition
    def execute(name)
      "Hello from Temporal Ruby SDK, #{name}!"
    end
  end
end
