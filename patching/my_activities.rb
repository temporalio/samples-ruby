# frozen_string_literal: true

require 'temporalio/activity'

module Patching
  module MyActivities
    class PrePatch < Temporalio::Activity::Definition
      def execute
        'pre-patch'
      end
    end

    class PostPatch < Temporalio::Activity::Definition
      def execute
        'post-patch'
      end
    end
  end
end
