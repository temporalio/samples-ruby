# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'triage_types'

# Companion HITL workflow.
#
# The triage agent's request_human_approval tool calls signal_with_start_workflow
# against a deterministic ID per alert group. This workflow stores the latest
# request, exposes it as a query, and returns the operator's decision.
class ApprovalWorkflow < Temporalio::Workflow::Definition
  workflow_name 'approvalWorkflow'

  def execute(_key)
    @request = nil
    @response = nil
    Temporalio::Workflow.wait_condition { !@request.nil? }
    Temporalio::Workflow.wait_condition { !@response.nil? }
    @response
  end

  workflow_signal name: 'approval-request'
  def approval_request(req)
    # LLM retry: re-attached requests overwrite. Operator only sees latest.
    @request = req
  end

  workflow_signal name: 'approval-decision'
  def approval_decision(res)
    @response = res
  end

  workflow_query name: 'pending-approval'
  def pending_approval
    @request
  end
end
