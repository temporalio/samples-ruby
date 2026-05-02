# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/worker'

require_relative 'approval_workflow'
require_relative 'triage_activity'
require_relative 'triage_workflow'

address = ENV.fetch('TEMPORAL_ADDRESS')
namespace = ENV.fetch('TEMPORAL_NAMESPACE')
api_key = ENV.fetch('TEMPORAL_API_KEY')
task_queue = ENV.fetch('TEMPORAL_TASK_QUEUE', 'triage-ruby')

puts "connecting to #{address} (ns=#{namespace}) on task queue #{task_queue}"

client = Temporalio::Client.connect(address, namespace, api_key: api_key, tls: true)
worker = Temporalio::Worker.new(
  client: client,
  task_queue: task_queue,
  workflows: [IncidentTriageWorkflow, ApprovalWorkflow],
  activities: [Triage::TriageIncidentActivity]
)

puts "worker ready — polling #{task_queue}"
worker.run
