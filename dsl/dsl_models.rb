# frozen_string_literal: true

module Dsl
  module Models
    # Base class for DSL input with root statement and variables
    class DslInput
      attr_reader :root, :variables

      def initialize(root, variables = {})
        @root = root
        @variables = variables
      end

      def to_h
        {
          'root' => @root.to_h,
          'variables' => @variables
        }
      end
    end

    # Activity invocation model
    class ActivityInvocation
      attr_reader :name, :arguments, :result

      def initialize(name, arguments = [], result = nil)
        @name = name
        @arguments = arguments
        @result = result
      end

      def to_h
        {
          'name' => @name,
          'arguments' => @arguments,
          'result' => @result
        }
      end
    end

    # Activity statement model
    class ActivityStatement
      attr_reader :activity

      def initialize(activity)
        @activity = activity
      end

      def to_h
        {
          'activity' => @activity.to_h
        }
      end
    end

    # Sequence model containing list of statements
    class Sequence
      attr_reader :elements

      def initialize(elements)
        @elements = elements
      end

      def to_h
        {
          'elements' => @elements.map(&:to_h)
        }
      end
    end

    # Sequence statement model
    class SequenceStatement
      attr_reader :sequence

      def initialize(sequence)
        @sequence = sequence
      end

      def to_h
        {
          'sequence' => @sequence.to_h
        }
      end
    end

    # Parallel model containing list of branches
    class Parallel
      attr_reader :branches

      def initialize(branches)
        @branches = branches
      end

      def to_h
        {
          'branches' => @branches.map(&:to_h)
        }
      end
    end

    # Parallel statement model
    class ParallelStatement
      attr_reader :parallel

      def initialize(parallel)
        @parallel = parallel
      end

      def to_h
        {
          'parallel' => @parallel.to_h
        }
      end
    end

    # Parse YAML to DSL models
    class Parser
      def self.parse_yaml(yaml_content)
        require 'yaml'
        data = YAML.safe_load(yaml_content)

        variables = data['variables'] || {}
        root = parse_statement(data['root'])

        DslInput.new(root, variables)
      end

      def self.parse_statement(data)
        case data.keys.first
        when 'activity'
          activity_data = data['activity']
          activity = ActivityInvocation.new(
            activity_data['name'],
            activity_data['arguments'] || [],
            activity_data['result']
          )
          ActivityStatement.new(activity)
        when 'sequence'
          sequence_data = data['sequence']
          elements = sequence_data['elements'].map { |elem| parse_statement(elem) }
          SequenceStatement.new(Sequence.new(elements))
        when 'parallel'
          parallel_data = data['parallel']
          branches = parallel_data['branches'].map { |branch| parse_statement(branch) }
          ParallelStatement.new(Parallel.new(branches))
        else
          raise "Unknown statement type: #{data.keys.first}"
        end
      end
    end
  end
end
