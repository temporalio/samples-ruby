# frozen_string_literal: true
# encoding: UTF-8

require 'temporalio/activity'
require_relative 'generated/temporal/message_passing_protobuf/v1/workflows_pb'
require_relative 'generated/temporal/message_passing_protobuf/v1/values_pb'

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

      # Determine which languages to include
      languages_to_fetch = if input.languages.nil? || input.languages.empty?
                             GetGreetings.greetings.keys
                           else
                             input.languages.map(&:to_sym)
                           end

      # Build array of Greeting protobuf messages
      greeting_messages = languages_to_fetch.map do |lang|
        greeting_text = GetGreetings.greetings[lang]
        Temporal::MessagePassingProtobuf::V1::Greeting.new(
          language: lang.to_s,
          greeting: greeting_text || ''
        )
      end

      # Return GetGreetingsResponse
      Temporal::MessagePassingProtobuf::V1::GetGreetingsResponse.new(
        greetings: greeting_messages
      )
    end
    def self.greetings
      # Temporarily using ASCII-only greetings to debug encoding issues
      # Original greetings:
      # arabic: 'مرحبا بالعالم',
      # chinese: '你好，世界',
      # french: 'Bonjour, monde',
      # hindi: 'नमस्ते दुनिया',
      # portuguese: 'Olá mundo',
      @greetings ||= {
        arabic: 'Marhaba!',
        chinese: 'Ni hao!',
        english: 'Hello, world',
        french: 'Bonjour!',
        hindi: 'Namaste!',
        portuguese: 'Ola!',
        spanish: 'Hola mundo'
      }
    end
  end
end
