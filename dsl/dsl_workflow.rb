# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'dsl_models'
require_relative 'activities'

module Dsl
  class DslWorkflow < Temporalio::Workflow::Definition
    def execute(input)
      Temporalio::Workflow.logger.info('Running DSL workflow')

      # Parse input - it could be a string (YAML) or a hash (already parsed)
      parsed_input = parse_input(input)
      @variables = parsed_input[:variables].dup

      # Execute the root statement
      execute_statement(parsed_input[:root])

      Temporalio::Workflow.logger.info('DSL workflow completed')

      # Return the final variables state
      @variables
    end

    private

    # Safely parse the input
    def parse_input(input)
      if input.is_a?(String)
        # Run YAML parsing in an unsafe block since it's non-deterministic
        Temporalio::Workflow::Unsafe.illegal_call_tracing_disabled do
          require 'yaml'
          data = YAML.safe_load(input)

          variables = data['variables'] || {}
          root = parse_data_to_statement(data['root'])

          { variables: variables, root: root }
        end
      elsif input.is_a?(Hash)
        # It's already a hash, extract variables and root
        variables = input['variables'] || {}
        root = parse_data_to_statement(input['root'])

        { variables: variables, root: root }
      else
        # For other types (like the DslInput object)
        begin
          { variables: input.variables, root: input.root }
        rescue NoMethodError
          raise "Invalid input format: #{input.class}. Expected String, Hash, or DslInput object."
        end
      end
    end

    # Parse statement data into appropriate objects
    def parse_data_to_statement(data)
      return nil unless data.is_a?(Hash)

      if data.key?('activity')
        activity_data = data['activity']
        activity = Models::ActivityInvocation.new(
          activity_data['name'],
          activity_data['arguments'] || [],
          activity_data['result']
        )
        Models::ActivityStatement.new(activity)
      elsif data.key?('sequence')
        sequence_data = data['sequence']
        elements = sequence_data['elements'].map { |elem| parse_data_to_statement(elem) }
        Models::SequenceStatement.new(Models::Sequence.new(elements))
      elsif data.key?('parallel')
        parallel_data = data['parallel']
        branches = parallel_data['branches'].map { |branch| parse_data_to_statement(branch) }
        Models::ParallelStatement.new(Models::Parallel.new(branches))
      else
        raise "Unknown statement type: #{data.keys.first}"
      end
    end

    def execute_statement(stmt)
      case stmt
      when Models::ActivityStatement
        # Execute activity statement with variable resolution
        execute_activity_statement(stmt)
      when Models::SequenceStatement
        # Execute each statement in sequence
        execute_sequence_statement(stmt)
      when Models::ParallelStatement
        # Execute branches in parallel
        execute_parallel_statement(stmt)
      else
        raise "Unknown statement type: #{stmt.class}"
      end
    end

    def execute_activity_statement(stmt)
      activity = stmt.activity

      # Resolve activity name to the appropriate activity class
      activity_class = activity_name_to_class(activity.name)

      # Resolve arguments from variables
      args = activity.arguments.map { |arg| @variables[arg] || arg }

      # Execute the activity
      result = Temporalio::Workflow.execute_activity(
        activity_class,
        *args,
        start_to_close_timeout: 5 * 60 # 5 minutes
      )

      # Store result in variables if result variable specified
      @variables[activity.result] = result if activity.result
    end

    def execute_sequence_statement(stmt)
      # Execute each statement in the sequence in order
      stmt.sequence.elements.each do |element|
        execute_statement(element)
      end
    end

    def execute_parallel_statement(stmt)
      futures = stmt.parallel.branches.map do |branch|
        Temporalio::Workflow::Future.new { execute_statement(branch) }
      end
      Temporalio::Workflow::Future.all_of(*futures).wait

      futures.map(&:result)
    end

    def activity_name_to_class(name)
      # Map activity name to appropriate activity class
      case name
      when 'activity1'
        Activities::Activity1
      when 'activity2'
        Activities::Activity2
      when 'activity3'
        Activities::Activity3
      when 'activity4'
        Activities::Activity4
      when 'activity5'
        Activities::Activity5
      else
        raise "Unknown activity name: #{name}"
      end
    end
  end
end
