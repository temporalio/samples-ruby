# frozen_string_literal: true

require 'minitest/autorun'
require 'time'

$LOAD_PATH.unshift(File.expand_path('..', __dir__))

require 'triage_types'
require 'triage_activity'

class FakeSession
  attr_reader :results

  def initialize
    @results = []
  end

  def add_result(r)
    @results << r
  end
end

class TriageActivityTest < Minitest::Test
  def make_alert
    TriageTypes::AlertPayload.new(
      status: 'firing',
      labels: { 'alertname' => 'HighLatencyP99', 'service' => 'api', 'runbook' => 'rollback-or-scale' },
      annotations: { 'summary' => 'P99 > 1s', 'description' => 'P99 above threshold for 1m.' },
      starts_at: Time.now.utc.iso8601
    )
  end

  def make_deps(overrides = {})
    Triage::TriageDeps.new(
      mcp_list_tools: overrides[:mcp_list_tools] || lambda do |url|
        if url.include?('7071')
          [{ name: 'prometheus_query', description: 'instant PromQL query',
             input_schema: { 'type' => 'object', 'properties' => { 'query' => { 'type' => 'string' } }, 'required' => ['query'] } }]
        else
          [{ name: 'kubectl_describe', description: 'describe a k8s resource',
             input_schema: { 'type' => 'object',
                             'properties' => { 'resource' => { 'type' => 'string' }, 'name' => { 'type' => 'string' }, 'namespace' => { 'type' => 'string' } },
                             'required' => %w[resource name] } }]
        end
      end,
      mcp_call_tool: overrides[:mcp_call_tool] || ->(_url, name, _args) { "(mocked #{name})" },
      request_human_approval: overrides[:request_human_approval] || lambda do |_alert, _req|
        TriageTypes::ApprovalResponse.new(decision: 'approved', reason: 'default-mock')
      end,
      exec_shell_command: overrides[:exec_shell_command] || ->(cmd) { ["(mocked exec: #{cmd})", ''] }
    )
  end

  def drive(deps, calls)
    session = FakeSession.new
    registry, get_result = Triage.build_triage_registry(make_alert, session, deps)
    calls.each { |name, input| registry.dispatch(name, input) }
    [get_result.call, session.results]
  end

  def test_happy_path_resolved
    approval_calls = 0
    approve = lambda do |_alert, _req|
      approval_calls += 1
      TriageTypes::ApprovalResponse.new(decision: 'approved', reason: 'go ahead')
    end
    deps = make_deps(request_human_approval: approve)
    action = 'kubectl rollout restart deploy/api -n demo-app'

    result, session_results = drive(deps, [
      ['prometheus_query', { 'query' => "up{service='api'}" }],
      ['kubectl_describe', { 'resource' => 'pod', 'name' => 'api-xyz', 'namespace' => 'demo-app' }],
      ['propose_remediation', { 'action' => action, 'justification' => 'leak; restart reclaims memory' }],
      ['request_human_approval', { 'message' => 'Restart api?', 'diagnosis' => 'memory leak', 'proposedAction' => action }],
      ['execute_remediation', { 'action' => action }],
      ['report_resolved', { 'summary' => 'restarted; latency normal' }]
    ])

    assert_equal 'resolved', result.status
    assert_match(/restart/, result.summary)
    assert_equal 1, result.remediations.length
    assert_equal action, result.remediations[0].action
    assert_equal 1, approval_calls

    kinds = session_results.map { |r| r['kind'] }
    assert_equal %w[remediation approval executed final], kinds
  end

  def test_rejected_approval_unresolved
    deps = make_deps(request_human_approval: lambda do |_a, _r|
      TriageTypes::ApprovalResponse.new(decision: 'rejected', reason: 'off-hours; defer until tomorrow')
    end)

    result, session_results = drive(deps, [
      ['propose_remediation', { 'action' => 'kubectl scale ...', 'justification' => 'transient' }],
      ['request_human_approval', { 'message' => 'Scale?', 'diagnosis' => 'transient', 'proposedAction' => 'kubectl scale ...' }],
      ['report_unresolved', { 'summary' => 'operator deferred' }]
    ])

    assert_equal 'unresolved', result.status
    assert_match(/deferred/, result.summary)
    approval = session_results.find { |r| r['kind'] == 'approval' }
    refute_nil approval
    assert_equal 'rejected', approval['decision']
    assert_match(/off-hours/, approval['reason'])
  end

  def test_execute_refuses_without_approval
    executed = []
    deps = make_deps(exec_shell_command: ->(cmd) { executed << cmd; ['ran', ''] })
    result, _ = drive(deps, [
      ['execute_remediation', { 'action' => 'rm -rf /' }],
      ['report_unresolved', { 'summary' => 'tried to skip approval' }]
    ])
    assert_equal 'unresolved', result.status
    assert_empty executed
  end

  def test_execute_refuses_when_action_does_not_match
    executed = []
    deps = make_deps(
      request_human_approval: ->(_a, _r) { TriageTypes::ApprovalResponse.new(decision: 'approved', reason: 'ok') },
      exec_shell_command: ->(cmd) { executed << cmd; ['ran', ''] }
    )

    result, _ = drive(deps, [
      ['propose_remediation', { 'action' => 'kubectl restart api', 'justification' => 'x' }],
      ['request_human_approval', { 'message' => 'Restart?', 'diagnosis' => 'x', 'proposedAction' => 'kubectl restart api' }],
      ['execute_remediation', { 'action' => 'kubectl scale deploy/api --replicas=10' }],
      ['report_unresolved', { 'summary' => 'guard tripped' }]
    ])

    assert_equal 'unresolved', result.status
    assert_empty executed, 'exec_shell_command should not have been called'
  end

  def test_mcp_tools_registered
    deps = make_deps
    session = FakeSession.new
    registry, _ = Triage.build_triage_registry(make_alert, session, deps)
    names = registry.to_anthropic.map { |t| t[:name] || t['name'] }
    %w[prometheus_query kubectl_describe propose_remediation request_human_approval
       execute_remediation report_resolved report_unresolved].each do |want|
      assert_includes names, want
    end
  end

  def test_mcp_dispatch_forwards_to_sidecar
    calls = []
    deps = make_deps(mcp_call_tool: lambda do |url, name, args|
      calls << { url: url, name: name, args: args }
      "result for #{name}"
    end)

    drive(deps, [
      ['prometheus_query', { 'query' => 'up{}' }],
      ['report_unresolved', { 'summary' => 'test' }]
    ])

    assert_equal 1, calls.length
    assert_equal 'prometheus_query', calls[0][:name]
    assert_includes calls[0][:url], '7071'
    assert_equal 'up{}', calls[0][:args]['query']
  end
end
