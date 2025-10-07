# frozen_string_literal: true

require 'json/add/struct'
require 'yaml'

module Dsl
  module Models
    Input = Struct.new(:root, :variables) do
      def self.from_yaml(yaml_str)
        from_h(YAML.load(yaml_str))
      end

      def self.from_h(hash)
        new(
          root: Statement.from_h(hash['root'] || raise('Missing root')),
          variables: hash['variables'] || {}
        )
      end
    end

    module Statement
      def self.from_h(hash)
        raise 'Expected single activity, sequence, or parallel field' unless hash.one?

        type, sub_hash = hash.first
        case type
        when 'activity' then Activity.from_h(sub_hash)
        when 'sequence' then Sequence.from_h(sub_hash)
        when 'parallel' then Parallel.from_h(sub_hash)
        else raise 'Expected single activity, sequence, or parallel field'
        end
      end

      Activity = Struct.new(:name, :arguments, :result) do
        def self.from_h(hash)
          new(name: hash['name'], arguments: hash['arguments'], result: hash['result'])
        end
      end

      Sequence = Struct.new(:elements) do
        def self.from_h(hash)
          new(elements: hash['elements'].map { |e| Statement.from_h(e) })
        end
      end

      Parallel = Struct.new(:branches) do
        def self.from_h(hash)
          new(branches: hash['branches'].map { |e| Statement.from_h(e) })
        end
      end
    end
  end
end
