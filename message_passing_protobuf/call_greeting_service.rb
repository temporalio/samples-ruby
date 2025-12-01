# frozen_string_literal: true

require 'temporalio/activity'

module MessagePassingProtobuf
  class CallGreetingService < Temporalio::Activity::Definition
    def execute(to_language)
      # Simulate a network call
      sleep(0.2)
      # This intentionally returns nil on not found
      GetGreetings.greetings[to_language.to_sym]
    end


  end

  class GetGreetings < Temporalio::Activity::Definition
    def execute(input)
      # Simulate a network call
      sleep(0.2)

      # If no filter provided, return all greetings
      return GetGreetings.greetings if input.languages.nil? || input.languages.empty?

      # Filter to requested languages, with nil for missing ones
      input.languages.each_with_object({}) do |lang, result|
        lang_sym = lang.to_sym
        result[lang_sym] = GetGreetings.greetings[lang_sym]
      end
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
