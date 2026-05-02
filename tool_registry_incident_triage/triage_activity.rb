# frozen_string_literal: true

require 'json'
require 'net/http'
require 'open3'
require 'uri'

require 'temporalio/activity'
require 'temporalio/client'
require 'temporalio/contrib/tool_registry'

require_relative 'approval_workflow'
require_relative 'triage_types'

# Ruby port of the triage activity. Mirrors workers/typescript, workers/python,
# workers/go.
#
# Structure: build_triage_registry returns [registry, get_result_lambda]. Pure
# modulo deps. The activity entrypoint composes AgenticSession.run_with_session
# + the registry + Anthropic provider.
module Triage
  SYSTEM_PROMPT = <<~PROMPT
    You are an SRE on-call agent triaging a production alert.

    You have these tools (sourced from MCP sidecars + per-language helpers):
      - prometheus_query(query)            instant PromQL query
      - prometheus_query_range(query, start, end, step)
      - prometheus_alerts()                what is currently firing
      - kubectl_get(resource, namespace?)  list K8s resources
      - kubectl_describe(resource, name, namespace?)
      - kubectl_logs(pod, namespace, tail?)
      - propose_remediation(action, justification)   record but do NOT execute
      - request_human_approval(message, diagnosis, proposedAction)
                                           blocks until operator says approve|reject
      - execute_remediation(action)        ONLY callable AFTER approval was approved.
                                           Pass the same action you got approved.
      - report_resolved(summary)           ends the loop with status=resolved
      - report_unresolved(summary)         ends the loop with status=unresolved

    Workflow:
      1. Read the alert. Use prometheus_query to confirm the symptom is currently true.
      2. Use kubectl_get/describe/logs and prometheus_query_range to find root cause.
      3. propose_remediation with a specific action (e.g., "kubectl rollout restart deploy/api -n demo-app").
      4. request_human_approval, attaching your diagnosis and the proposed action.
      5. If approved: execute_remediation, then prometheus_query to verify the symptom is gone, then report_resolved.
      6. If rejected: report_unresolved with the operator's reason.

    Be terse. Conversation history is heartbeated to Temporal — keep tool inputs short.
  PROMPT

  # TriageDeps holds injectable I/O. Tests substitute their own.
  TriageDeps = Struct.new(
    :mcp_list_tools,         # ->(base_url) returns array of {name, description, input_schema}
    :mcp_call_tool,          # ->(base_url, name, args) returns String
    :request_human_approval, # ->(alert, request) returns ApprovalResponse
    :exec_shell_command,     # ->(cmd) returns [stdout, stderr]
    keyword_init: true
  )

  def self.default_mcp_list_tools(base_url)
    body = mcp_rpc(base_url, 'tools/list', nil)
    parsed = JSON.parse(body)
    raise "mcp tools/list #{base_url}: #{parsed['error']['message']}" if parsed['error']

    (parsed.dig('result', 'tools') || []).map do |t|
      {
        name: t['name'],
        description: t['description'] || '',
        input_schema: t['inputSchema'] || { 'type' => 'object' }
      }
    end
  end

  def self.default_mcp_call_tool(base_url, name, args)
    body = mcp_rpc(base_url, 'tools/call', { 'name' => name, 'arguments' => args })
    parsed = JSON.parse(body)
    return "MCP error: #{parsed['error']['message']}" if parsed['error']

    blocks = parsed.dig('result', 'content') || []
    blocks.map { |b| b['text'] || '' }.join("\n")
  end

  def self.mcp_rpc(base_url, method, params)
    uri = URI(base_url)
    payload = { jsonrpc: '2.0', id: Time.now.to_i, method: method }
    payload[:params] = params if params
    req = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
    req['Content-Type'] = 'application/json'
    req.body = payload.to_json
    Net::HTTP.start(uri.hostname, uri.port, read_timeout: 30) { |http| http.request(req) }.body
  end

  def self.default_exec_shell_command(cmd)
    stdout, stderr, _status = Open3.capture3(cmd)
    [stdout, stderr]
  end

  def self.default_deps
    TriageDeps.new(
      mcp_list_tools: ->(url) { default_mcp_list_tools(url) },
      mcp_call_tool: ->(url, name, args) { default_mcp_call_tool(url, name, args) },
      request_human_approval: ->(alert, req) { real_request_human_approval(alert, req) },
      exec_shell_command: ->(cmd) { default_exec_shell_command(cmd) }
    )
  end

  def self.build_triage_registry(alert, session, deps)
    registry = Temporalio::Contrib::ToolRegistry::Registry.new
    prom_mcp = ENV.fetch('MCP_PROMETHEUS_URL', 'http://localhost:7071/')
    k8s_mcp = ENV.fetch('MCP_KUBERNETES_URL', 'http://localhost:7072/')

    register_mcp_tools(registry, prom_mcp, deps)
    register_mcp_tools(registry, k8s_mcp, deps)

    remediations = []
    approved_action = nil
    final = nil

    registry.register(
      name: 'propose_remediation',
      description: 'Record a remediation you would apply. Does NOT execute it.',
      input_schema: {
        'type' => 'object',
        'properties' => {
          'action' => { 'type' => 'string' },
          'justification' => { 'type' => 'string' }
        },
        'required' => %w[action justification]
      }
    ) do |inp|
      r = TriageTypes::ProposedRemediation.new(action: inp['action'].to_s, justification: inp['justification'].to_s)
      remediations << r
      session.add_result({ 'kind' => 'remediation', 'action' => r.action, 'justification' => r.justification })
      'recorded'
    end

    registry.register(
      name: 'request_human_approval',
      description: 'Block until operator decides. Returns JSON {decision, reason}.',
      input_schema: {
        'type' => 'object',
        'properties' => {
          'message' => { 'type' => 'string' },
          'diagnosis' => { 'type' => 'string' },
          'proposedAction' => { 'type' => 'string' }
        },
        'required' => %w[message diagnosis proposedAction]
      }
    ) do |inp|
      req = TriageTypes::ApprovalRequest.new(
        message: inp['message'].to_s,
        diagnosis: inp['diagnosis'].to_s,
        proposed_action: inp['proposedAction'].to_s
      )
      resp = deps.request_human_approval.call(alert, req)
      approved_action = req.proposed_action if resp.decision == 'approved'
      session.add_result({ 'kind' => 'approval', 'decision' => resp.decision, 'reason' => resp.reason })
      { decision: resp.decision, reason: resp.reason }.to_json
    end

    registry.register(
      name: 'execute_remediation',
      description: 'Execute the previously-approved action. Errors if no approval has been granted.',
      input_schema: {
        'type' => 'object',
        'properties' => { 'action' => { 'type' => 'string' } },
        'required' => %w[action]
      }
    ) do |inp|
      action = inp['action'].to_s
      if approved_action.nil?
        next 'ERROR: no approval has been granted. Call request_human_approval first.'
      end
      if action != approved_action
        next "ERROR: requested action does not match approved action. Approved: #{approved_action}"
      end

      stdout, stderr = deps.exec_shell_command.call(action)
      session.add_result({
        'kind' => 'executed', 'action' => action,
        'stdout' => stdout[0, 2000], 'stderr' => stderr[0, 2000]
      })
      out = !stdout.empty? ? stdout : (!stderr.empty? ? stderr : 'ok')
      out[0, 4000]
    end

    registry.register(
      name: 'report_resolved',
      description: 'Ends the loop with status=resolved.',
      input_schema: {
        'type' => 'object',
        'properties' => { 'summary' => { 'type' => 'string' } },
        'required' => %w[summary]
      }
    ) do |inp|
      final = TriageTypes::TriageResult.new(
        status: 'resolved', summary: inp['summary'].to_s, remediations: remediations.dup
      )
      session.add_result({ 'kind' => 'final', 'status' => final.status, 'summary' => final.summary })
      'ok'
    end

    registry.register(
      name: 'report_unresolved',
      description: 'Ends the loop with status=unresolved.',
      input_schema: {
        'type' => 'object',
        'properties' => { 'summary' => { 'type' => 'string' } },
        'required' => %w[summary]
      }
    ) do |inp|
      final = TriageTypes::TriageResult.new(
        status: 'unresolved', summary: inp['summary'].to_s, remediations: remediations.dup
      )
      session.add_result({ 'kind' => 'final', 'status' => final.status, 'summary' => final.summary })
      'ok'
    end

    [registry, -> { final }]
  end

  def self.register_mcp_tools(registry, base_url, deps)
    tools = deps.mcp_list_tools.call(base_url)
    tools.each do |t|
      name = t[:name]
      registry.register(
        name: name,
        description: t[:description] || '',
        input_schema: t[:input_schema] || { 'type' => 'object' }
      ) { |input| deps.mcp_call_tool.call(base_url, name, input) }
    end
  rescue StandardError
    # MCP server unreachable in testing or at boot — proceed without these tools.
  end

  def self.build_prompt(alert)
    labels = alert.labels || {}
    annotations = alert.annotations || {}
    "Alert fired: #{labels['alertname'] || 'unknown'} on #{labels['service'] || 'unknown'}.\n" \
      "Summary: #{annotations['summary'] || '(none)'}\n" \
      "Description: #{annotations['description'] || '(none)'}\n" \
      "Runbook hint: #{labels['runbook'] || '(none)'}\n\n" \
      'Investigate, propose, get approval, and either fix or report unresolved.'
  end

  # Activity entrypoint registered with the worker.
  class TriageIncidentActivity < Temporalio::Activity::Definition
    activity_name 'triage_incident_activity'

    def execute(alert)
      result = nil
      Temporalio::Contrib::ToolRegistry::AgenticSession.run_with_session do |session|
        registry, get_result = Triage.build_triage_registry(alert, session, Triage.default_deps)
        provider = Temporalio::Contrib::ToolRegistry::Providers::AnthropicProvider.new(
          registry, Triage::SYSTEM_PROMPT, api_key: ENV['ANTHROPIC_API_KEY']
        )
        session.run_tool_loop(provider, registry, Triage.build_prompt(alert))
        result = get_result.call
      end
      raise 'Agent ended the loop without calling report_resolved or report_unresolved' if result.nil?

      result
    end
  end

  def self.real_request_human_approval(alert, req)
    api_key = ENV.fetch('TEMPORAL_API_KEY')
    address = ENV.fetch('TEMPORAL_ADDRESS')
    namespace = ENV.fetch('TEMPORAL_NAMESPACE')
    task_queue = ENV.fetch('TEMPORAL_TASK_QUEUE', 'triage-ruby')

    client = Temporalio::Client.connect(address, namespace, api_key: api_key, tls: true)
    key = "#{(alert.labels['alertname'] || 'unknown').downcase}-#{(alert.labels['service'] || 'unknown').downcase}"
    wf_id = "approval-#{key}"

    handle = client.start_workflow(
      ApprovalWorkflow,
      key,
      id: wf_id,
      task_queue: task_queue,
      start_signal: 'approval-request',
      start_signal_args: [req]
    )
    handle.result
  end
end
