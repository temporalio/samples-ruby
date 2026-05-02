# frozen_string_literal: true

# Client CLI for the Ruby triage workers.
#
# Usage:
#   ruby client.rb approve <workflow-id> <reason>
#   ruby client.rb reject  <workflow-id> <reason>
#   ruby client.rb trigger <alertname> <service>
#
# Listing pending approval workflows: use the Temporal CLI directly.
require 'temporalio/client'
require_relative 'triage_types'
require_relative 'approval_workflow'
require_relative 'triage_workflow'

def make_client
  Temporalio::Client.connect(
    ENV.fetch('TEMPORAL_ADDRESS'),
    ENV.fetch('TEMPORAL_NAMESPACE'),
    api_key: ENV.fetch('TEMPORAL_API_KEY'),
    tls: true
  )
end

def decide(decision, workflow_id, reason)
  client = make_client
  handle = client.workflow_handle(workflow_id)
  handle.signal('approval-decision', TriageTypes::ApprovalResponse.new(decision: decision, reason: reason))
  puts "signaled #{workflow_id}: #{decision} — #{reason}"
end

def trigger(alertname, service)
  client = make_client
  task_queue = ENV.fetch('TEMPORAL_TASK_QUEUE', 'triage-ruby')
  wf_id = "triage-#{alertname.downcase}-#{service.downcase}"
  alert = TriageTypes::AlertPayload.new(
    status: 'firing',
    labels: { 'alertname' => alertname, 'service' => service, 'severity' => 'critical', 'runbook' => 'synthetic' },
    annotations: {
      'summary' => "Synthetic test alert for #{service}",
      'description' => 'Triggered manually via client.rb to exercise the triage flow.'
    },
    starts_at: Time.now.utc.iso8601
  )
  handle = client.start_workflow(
    IncidentTriageWorkflow, alert,
    id: wf_id, task_queue: task_queue,
    start_signal: 'alert-update', start_signal_args: [alert]
  )
  puts "started triage workflow: #{handle.id} on #{task_queue}"
end

cmd, *args = ARGV
case cmd
when 'approve'
  abort 'Usage: client.rb approve <wfid> <reason>' if args.length < 2
  decide('approved', args[0], args[1..].join(' '))
when 'reject'
  abort 'Usage: client.rb reject <wfid> <reason>' if args.length < 2
  decide('rejected', args[0], args[1..].join(' '))
when 'trigger'
  abort 'Usage: client.rb trigger <alertname> <service>' if args.length < 2
  trigger(args[0], args[1])
else
  abort 'Usage: ruby client.rb <approve|reject|trigger> ...'
end
