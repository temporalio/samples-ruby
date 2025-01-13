# frozen_string_literal: true

require 'temporalio/activity'

module MessagePassingSimple
  class CallGreetingService < Temporalio::Activity::Definition
    def execute(to_language)
      # Simulate a network call
      sleep(0.2)
      # This intentionally returns nil on not found
      CallGreetingService.greetings[to_language.to_sym]
    end

    def self.greetings
      @greetings ||= {
        arabic: 'مرحبا بالعالم',
        chinese: '你好，世界',
        english: 'Hello, world',
        french: 'Bonjour, monde',
        hindi: 'नमस्ते दुनिया',
        portuguese: 'Olá mundo',
        spanish: 'Hola mundo'
      }
    end
  end
end
